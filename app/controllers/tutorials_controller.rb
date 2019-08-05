class TutorialsController < ApplicationController

  def introduction
    @md_content = Rails.root.join('documentation', 'introduction.md').read
  end

  def using_edurange
    type = (current_user.admin? or current_user.instructor?) ?
 'instructors' : 'students'
    file = Rails.root.join('documentation', "using_edurange_for_#{type}.md")
    @md_content = file.read
  end

  def instructor_manual
    manual 'Instructor'
  end

  def student_manual
    manual 'Student'
  end

  def manual variant
    respond_to do |format|
      format.pdf do
        send_file(
          Rails.root.join('documentation', "EDURange_#{variant}_Manual.pdf"),
          disposition: 'inline',
          type: 'application/pdf'
        )
      end
    end
  end

end
