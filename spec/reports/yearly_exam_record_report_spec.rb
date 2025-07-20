require 'rails_helper'

RSpec.describe YearlyExamRecordReport, type: :report do
  context 'should be created' do
    let!(:entity_configuration){ create(:entity_configuration) }
    let!(:discipline){ create(:discipline) }
    let!(:classroom){
      create(
        :classroom,
        :with_classroom_semester_steps,
        :with_teacher_discipline_classroom,
        :with_student_enrollment_classroom,
        discipline: discipline
      )
    }
    let!(:school_calendar){ classroom.calendar.school_calendar }
    let!(:student){ classroom.student_enrollment_classrooms.first.student_enrollment.student }
    let!(:avaliation){
      create(
        :avaliation,
        school_calendar: school_calendar,
        classroom: classroom,
        discipline: discipline,
        teacher_id: classroom.teacher_discipline_classrooms.first.teacher_id,
        test_date: Date.current
      )
    }
    let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
    let!(:teacher) { create(:teacher) }
    let!(:test_setting) { create(:test_setting) }
    let!(:daily_note_student) { create(:daily_note_student, daily_note: daily_note, student: student) }

    it 'successfully creates the YearlyExamRecordReport' do
      resource_params = {
        unity_id: classroom.unity_id,
        classroom_id: classroom.id,
        discipline_id: discipline.id
      }

      form = YearlyExamRecordReportForm.new(resource_params)

      subject = YearlyExamRecordReport.build(
        entity_configuration,
        teacher,
        classroom,
        discipline,
        form
      ).render

      expect(subject).to be_truthy
    end
  end
end
