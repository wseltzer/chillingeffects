require 'spec_helper'

describe 'notices/search/index.html.erb' do
  it "display the results" do
    mock_searcher(build_stubbed_list(:dmca, 5))

    render

    expect(page).to have_css('.result', count: 5)
  end

  it "includes facets" do
    mock_searcher(build_stubbed_list(:dmca, 1))

    render

    facet_data.keys.each do|facet|
      expect(page).to have_css(".#{facet} span", count: 2)
    end
  end

  it "displays correct content when a notice only has a principal" do
    notice = create(
      :dmca,
      role_names: %w( principal ),
      title: 'A notice'
    )
    mock_searcher([notice])

    render

    within('.result') do
      expect(page).not_to have_content('on behalf of')
      expect(page).not_to have_content('/faceted_search')
    end
  end

  context "notice is sent on behalf of an entity" do
    before do
      @notice = create(
        :dmca,
        role_names: %w( sender principal recipient ),
        title: 'A notice',
        date_received: Time.now,
        topics: build_list(:topic, 2)
      )
      @on_behalf_of = "#{@notice.sender_name} on behalf of #{@notice.principal_name}"
      mock_searcher([@notice])
    end

    it "has facet links for all relevant entities" do

      render

      within('.result') do
        expect(page).to have_faceted_search_role_link(:sender_name, @notice)
        expect(page).to have_faceted_search_role_link(:recipient_name, @notice)
        expect(page).to have_faceted_search_role_link(:principal_name, @notice)
      end
    end

    it "includes the relevant notice data" do

      render

      within('.result') do
        expect(page).to have_css('.title', text: 'A notice')
        expect(page).to have_css(
          '.date-received', text: @notice.date_received.to_s(:simple)
        )
        expect(page).to have_content(@on_behalf_of)
        within('.topic') do
          @notice.topics.each do |topic|
            expect(page).to have_content(topic.name)
          end
        end
        expect(page).to contain_link(notice_path(@notice))
      end
    end
  end

  context 'excerpts' do
    it "includes excerpts" do
      mock_searcher(
        [build_stubbed(:dmca)],
        'highlight' => { 'title' => ["foo <em>bar</em> baz"] }
      )

      render

      within('.result') do
        expect(page).to have_content('foo bar baz')
      end
    end

    it 'sanatizes excerpts' do
      mock_searcher(
        [build_stubbed(:dmca)],
        'highlight' => { 'title' => ["<strong>foo</strong> and <em>bar</em>"] }
      )

      render

      expect(rendered).to include('foo and <em>bar</em>')
    end
  end

  private

  def mock_searcher(notices, options = {})
    results = notices.map { |notice| as_tire_result(notice, options) }
    results.stub(:total_entries, results.length)
    results.stub(:total_pages).and_return(1)
    results.stub(:facets).and_return(facet_data)
    results.stub(:current_page).and_return(1)
    results.stub(:limit_value).and_return(1)

    search_results = double('results double')
    search_results.stub(:results).and_return(results)

    searcher = double('searcher double')
    searcher.stub(:search).and_return(search_results)
    searcher.stub(:cache_key).and_return('asdfasdf')
    assign(:searcher, searcher)
  end

  def facet_data
    {
      "sender_name_facet" => { "terms" =>
        [
          { "term" => "Mike's Lawyer", "count" => 27 },
          { "term" => "Imak's Lawyer", "count" => 27 }
        ]
      },
      "principal_name_facet" => { "terms" =>
        [
          { "term" => "Mike Itten", "count" => 27 },
          { "term" => "Imak Itten", "count" => 27 }
        ]
      },
      "recipient_name_facet" => { "terms" =>
        [
          { "term" => "Twitter", "count" => 10 },
          { "term" => "Twooter", "count" => 10 }
        ]
      },
      "topic_facet" => { "terms" =>
        [
          { "term" => "DMCA", "count" => 10 },
          { "term" => "DMCA Giveup", "count" => 10 }
        ]
      },
      "tag_list_facet" => { "terms" =>
        [
          { "term" => "a tag", "count" => 27 },
          { "term" => "another tag", "count" => 27 }
        ]
      },
      "country_code_facet" => { "terms" =>
        [
          { "term" => "US", "count" => 27 },
          { "term" => "CA", "count" => 27 }
        ]
      },
      "language_facet" => { "terms" =>
        [
          { "term" => "EN", "count" => 27 },
          { "term" => "SP", "count" => 27 }
        ]
      },
      "date_received_facet"=>{ "ranges"=>
        [
          { "from" => 1371583484000.0, "to" => 1371669884000.0, "count" => 1},
          { "from" => 1371583485000.0, "to" => 1371669885000.0, "count" => 1}
        ]
      },
      "action_taken_facet" => { "terms" =>
        [
          { "term" => "No", "count" => 7 },
          { "term" => "Yes", "count" => 10 },
        ]
      },
    }
  end

  def have_faceted_search_role_link(role, notice)
    have_css(%Q(a[href="#{faceted_search_path(role => notice.send(role))}"]), text: notice.send(role))
  end

end
