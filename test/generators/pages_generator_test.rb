require 'test_helper'
require 'rails/generators/test_case'
require 'generators/omen/pages/pages_generator'

class Omen::Generators::PagesGeneratorTest < Rails::Generators::TestCase
  tests Omen::Generators::PagesGenerator
  destination Rails.root.join 'tmp/generated'
  setup :prepare_destination, :draw_routes

  test 'the pages are written under a name the host is free not to give' do
    run_generator

    assert_file 'app/models/inquiry.rb', /class Inquiry < Omen::Reading/
    assert_file 'app/controllers/inquiries_controller.rb', /class InquiriesController </
    assert_file 'app/views/inquiries/index.html.erb'
    assert_file 'app/views/inquiries/show.html.erb'
    assert_file 'app/views/inquiries/_form.html.erb'
    assert_file 'config/routes.rb', /resources :inquiries/
  end

  test 'a name of the host own is singular where a record is and plural where a page is' do
    run_generator %w[ Consultation ]

    assert_file 'app/models/consultation.rb', /class Consultation < Omen::Reading/
    assert_file 'app/controllers/consultations_controller.rb' do |written|
      assert_match(/@consultation = Consultation\.find/, written)
      assert_match(/params\.expect consultation: \[ :question \]/, written)
    end
    assert_file 'app/views/consultations/index.html.erb', /@consultations\.each/
    assert_file 'config/routes.rb', /resources :consultations/
  end

  test 'what is written is a controller that parses and views that compile' do
    run_generator

    assert_ruby 'app/models/inquiry.rb'
    assert_ruby 'app/controllers/inquiries_controller.rb'
    Omen::Generators::PagesGenerator::VIEWS.each do |view|
      assert_erb "app/views/inquiries/#{view}.html.erb"
    end
  end

  test 'the controller asks rather than edits, since a question said is said' do
    run_generator

    assert_file 'app/controllers/inquiries_controller.rb' do |written|
      assert_match(/@inquiry\.ask\(question\) if question\.present\?/, written)
      assert_no_match(/def edit/, written)
      assert_no_match(/def new/, written)
    end
  end

  test 'the answer is drawn from what may be read back, and never from the raw rows' do
    run_generator

    assert_file 'app/views/inquiries/show.html.erb' do |written|
      assert_match(/answer\.shown\.each do \|row\|/, written)
      assert_no_match(/answer\.result/, written)
    end
  end

  test 'a host with no Turbo is left the pages and nothing that would raise in them' do
    run_generator

    assert_file 'app/views/inquiries/show.html.erb' do |written|
      assert_no_match(/turbo_stream_from/, written)
    end
    assert_no_file 'config/initializers/omen_broadcasts.rb'
  end

  test 'a host with Turbo hears the refresh on the stream the gem broadcasts over' do
    with_turbo { run_generator }

    assert_file 'app/views/inquiries/show.html.erb',
      /turbo_stream_from @inquiry\.becomes\(Omen::Reading\)/
    assert_file 'config/initializers/omen_broadcasts.rb',
      /ActiveSupport\.on_load\(:omen_reading\) \{ broadcasts_refreshes \}/
  end

  test 'a name this app already answers to is refused rather than taken over' do
    Object.const_set :Presentiment, Class.new

    refused = capture(:stderr) { run_generator %w[ Presentiment ] }

    assert_match(/already used in your application/, refused)
    assert_no_file 'app/models/presentiment.rb'
    assert_no_file 'app/controllers/presentiments_controller.rb'
  ensure
    Object.send :remove_const, :Presentiment
  end

private

  # The route action edits this file rather than writing it, so the host has to have one.
  def draw_routes
    mkdir_p File.join destination_root, 'config'
    File.write File.join(destination_root, 'config/routes.rb'),
      "Rails.application.routes.draw do\nend\n"
  end

  def with_turbo
    Object.const_set :Turbo, Module.new
    yield
  ensure
    Object.send :remove_const, :Turbo
  end

  def assert_ruby(path)
    assert_file path do |written|
      RubyVM::InstructionSequence.compile written, path
    end
  end

  # Through the compiler Rails itself uses, since plain ERB cannot read `<%= form_with do %>`
  # and would call every one of these views a syntax error.
  def assert_erb(path)
    assert_file path do |written|
      RubyVM::InstructionSequence.compile ActionView::Template::Handlers::ERB::Erubi
        .new(written).src, path
    end
  end
end
