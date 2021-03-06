# frozen_string_literal: true

require 'rails_helper'

# These tests will fail if the test database is rebuilt using db:schema:load
# To fix, run the following from the command line:

# rails db:structure:load RAILS_ENV=test

RSpec.describe 'Visit the best efforts page and search for an effort' do
  let(:course) { courses(:hardrock_ccw) }
  let(:event) { events(:hardrock_2015) }
  let(:effort_1) { event.efforts.ranked_with_status.first }
  let(:other_efforts) { event.efforts.where.not(id: effort_1.id) }

  scenario 'Visitor visits the page and searches for a name' do
    visit best_efforts_course_path(course)

    expect(page).to have_content(course.name)
    finished_efforts = event.efforts.ranked_with_status.select(&:finished)

    finished_efforts.each { |effort| verify_link_present(effort, :full_name) }

    fill_in 'First name, last name, state, or country', with: effort_1.name
    click_button 'search-submit'
    wait_for_css

    verify_link_present(effort_1)
    other_efforts.each { |effort| verify_content_absent(effort) }
  end
end
