class YearlyExamRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id

  validates :unity_id,      presence: true
  validates :classroom_id,  presence: true
  validates :discipline_id, presence: true

  validate :must_have_daily_notes

  def daily_notes(step)
    DailyNote.by_unity_id(unity_id)
             .by_classroom_id(classroom_id)
             .by_discipline_id(discipline_id)
             .by_test_date_between(step.start_at, step.end_at)
             .order_by_avaliation_test_date
  end

  def recovery_lowest_notes?(step)
    AvaliationRecoveryLowestNote.by_unity_id(unity_id)
                               .by_classroom_id(classroom_id)
                               .by_discipline_id(discipline_id)
                               .by_step_id(classroom, step.id)
                               .exists?
  end

  def lowest_notes(step)
    lowest_notes = {}

    recovery_diary_record_students = RecoveryDiaryRecordStudent.by_student_id(student_ids(step))
                                                               .joins(:recovery_diary_record)
                                                               .merge(recovery_diary_records(step))

    recovery_diary_record_students.each do |recovery_diary_record|
      student_data = {recovery_diary_record.student_id => recovery_diary_record.score}
      lowest_notes = lowest_notes.merge(student_data)
    end

    lowest_notes
  end

  def daily_notes_classroom_steps(step)
    DailyNote.by_unity_id(unity_id)
             .by_classroom_id(classroom_id)
             .by_discipline_id(discipline_id)
             .by_test_date_between(step.start_at, step.end_at)
             .order_by_avaliation_test_date
  end

  def info_students(step)
    StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom_id,
      disciplines: discipline_id,
      start_at: step.start_at,
      end_at: step.end_at,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date_range,
      include_inactive: false
    )
  end

  def filter_unique_students(step)
    info_students(step).each_with_object({}) do |student, unique_students|
      student_id = student[:student].id
      unique_students[student_id] ||= student
    end.values
  end

  def student_ids(step)
    info_students(step).map { |info| info[:student].id }
  end

  def complementary_exams(step)
    ComplementaryExam
      .by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range(step.start_at, step.end_at)
      .order(recorded_at: :asc)
  end

  def school_term_recoveries(step)
    return [] unless GeneralConfiguration.current.show_school_term_recovery_in_exam_record_report?

    SchoolTermRecoveryDiaryRecord
      .includes(recovery_diary_record: :discipline)
      .by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_recorded_at(step.start_at..step.end_at)
      .order(recorded_at: :asc)
  end

  private

  def must_have_daily_notes
    return if errors.present?

    has_notes = StepsFetcher.new(classroom).steps.any? do |step|
      daily_notes(step).count > 0
    end

    errors.add(:daily_notes, :must_have_daily_notes) unless has_notes
  end

  def recovery_diary_records(step)
    RecoveryDiaryRecord.by_discipline_id(discipline_id)
                       .by_classroom_id(classroom_id)
                       .joins(:students, :avaliation_recovery_lowest_note)
                       .merge(AvaliationRecoveryLowestNote.by_step_id(classroom, step.id))
  end

  def classroom
    @classroom ||= Classroom.find(classroom_id)
  end
end
