require 'test_helper'
require 'rails/generators'
require 'generators/omen/pages/pages_generator'

# What `rails g omen:pages` leaves behind, served. The dummy stands in for the host: the files
# are generated into it, loaded, and then asked for over HTTP, so a page that parses but cannot
# draw a row fails here rather than in somebody's browser.
class Omen::Generators::PagesServeTest < ActionDispatch::IntegrationTest
  # Not tmp/generated, which the generator test owns and empties out from under this one.
  GENERATED = Rails.root.join 'tmp/served'

  FileUtils.rm_rf GENERATED
  FileUtils.mkdir_p GENERATED.join('config')
  GENERATED.join('config/routes.rb').write "Rails.application.routes.draw do\nend\n"
  Omen::Generators::PagesGenerator.start %w[ Divination --quiet ], destination_root: GENERATED

  # What every host has and the dummy has no other use for: the class the pages descend from,
  # and so the one whose before_actions guard them.
  Object.const_set :ApplicationController, Class.new(ActionController::Base)

  load GENERATED.join('app/models/divination.rb')
  load GENERATED.join('app/controllers/divinations_controller.rb')
  DivinationsController.prepend_view_path GENERATED.join('app/views')
  Rails.application.routes.draw { resources :divinations }

  setup do
    stub_claude claude_answers(sql: 'SELECT city, count(*) AS homes FROM homes GROUP BY city',
                               note: 'One row per city.')
  end

  test 'the index draws the form to ask with and a line for every reading' do
    answered 'Where are the homes we serve?'

    get divinations_path

    assert_response :success
    assert_select 'form textarea[name=?]', 'divination[question]'
    assert_select 'a', text: 'Where are the homes we serve?'
  end

  test 'asking opens a reading, since there is no page for a blank one' do
    assert_difference 'Omen::Reading.count', 1 do
      post divinations_path, params: { divination: { question: 'Where are the homes we serve?' } }
    end

    assert_redirected_to divination_path(Divination.last)
  end

  test 'a reading nobody asked anything is refused, and the index says so' do
    post divinations_path, params: { divination: { question: '' } }

    assert_response :unprocessable_content
    assert_select 'p', text: /can.t be blank/
  end

  test 'the show page draws the question, the statement and the rows it found' do
    divination = answered 'Where are the homes we serve?'

    get divination_path(divination)

    assert_response :success
    assert_select 'h2', text: 'Where are the homes we serve?'
    assert_select 'p', text: 'One row per city.'
    assert_select 'details pre', text: /SELECT city, count\(\*\)/
    assert_select 'table th', text: 'city'
    assert_select 'table td', text: 'Beverly Hills'
  end

  test 'asking again adds to the thread rather than editing what was said' do
    divination = answered 'Where are the homes we serve?'

    assert_difference -> { divination.questions.count }, 1 do
      patch divination_path(divination),
        params: { divination: { question: 'And how many bookings?' } }
      perform_enqueued_jobs
    end
    assert_redirected_to divination_path(divination)

    get divination_path(divination)
    assert_select 'h2', text: 'And how many bookings?'
  end

  test 'a follow-up nobody typed asks nothing, rather than asking Claude for nothing' do
    divination = answered 'Where are the homes we serve?'

    assert_no_difference -> { divination.questions.count } do
      patch divination_path(divination), params: { divination: { question: '  ' } }
    end
  end

  test 'the button the show page draws reaches an action that destroys' do
    divination = answered 'Where are the homes we serve?'

    assert_difference 'Omen::Reading.count', -1 do
      delete divination_path(divination)
    end

    assert_redirected_to divinations_path
  end

private

  def answered(question)
    Divination.create!(question: question).tap { perform_enqueued_jobs }
  end
end
