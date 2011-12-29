Fetch iTunes App Store reviews for each application, across all country stores. Reads rating, author, subject and review body.

Refactored from [Jeremy Wohl's script](https://github.com/jeremywohl/iphone-scripts) -> Derived from [Erica Sadun's scraper](http://blogs.oreilly.com/iphone/2008/08/scraping-appstore-reviews.html)

required gems: 
hpricot
httparty

# Example

You can find an app's id at the end of its App Store url:

http:// itunes.apple.com/us/app/italk-recorder-premium/id296271871?mt=8


	require 'appstore-scraper'

	apps = {
  		'iTalk' => 296271871,
	}

	stores = [
		'United States',
		'France',
	]

	scraper = AppstoreScraper.new
	scraper.fetch_latest_version_only = true
	scraper.max_reviews = 10
	scraper.sort_order = AppstoreScrapper::SortOrders::MOST_RECENT

	reviews = []
	begin
		apps.each_value do |app|
			stores.each do |store|
				scraper.set_store(store)
				reviews << scraper.fetch_reviews(app)
			end
		end
	rescue => e
		puts e.message
	end
