class YearlyExamRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @yearly_exam_record_report_form = YearlyExamRecordReportForm.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    )

    set_options_by_user
    fetch_disciplines_by_classroom
  end

  def report
    @yearly_exam_record_report_form = YearlyExamRecordReportForm.new(resource_params)

    if @yearly_exam_record_report_form.valid?
      yearly_exam_record_report = build_report
      send_pdf(t('routes.yearly_exam_record_report'), yearly_exam_record_report.render)
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      render :form
    end
  end


  private

  def resource_params
    params.require(:yearly_exam_record_report_form).permit(:unity_id,
                                                          :classroom_id,
                                                          :discipline_id)
  end

  def build_report
    classroom = Classroom.find(@yearly_exam_record_report_form.classroom_id)
    discipline = Discipline.find(@yearly_exam_record_report_form.discipline_id)

    YearlyExamRecordReport.build(
      current_entity_configuration,
      current_teacher,
      classroom,
      discipline,
      @yearly_exam_record_report_form
    )
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity,
current_school_year)
    classroom_id = @yearly_exam_record_report_form.classroom_id
    @disciplines ||= @fetch_linked_by_teacher[:disciplines].by_classroom_id(classroom_id)
                                                           .not_descriptor
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]

    fetch_linked_by_teacher
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom_id = @yearly_exam_record_report_form.classroom_id
    @disciplines = @disciplines.by_classroom_id(classroom_id).not_descriptor
  end
end
