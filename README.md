Fetch iTunes App Store reviews for each application, across all country stores, with translation. Reads rating, author, subject and review body. Apple's XML is purely layout-based, without much semantic relation to reviews, so the CSS paths are brittle.

Derived from Erica Sadun's scraper: ([oreilly.com](http://blogs.oreilly.com/iphone/2008/08/scraping-appstore-reviews.html))

Forked from Jeremy Wohl's script: ([github.com/jeremywohl/iphone-scripts](https://github.com/jeremywohl/iphone-scripts))

This class uses Google's translate API. ([Terms of Service](http://code.google.com/apis/language/translate/terms.html))

required gems: 
hpricot
httparty

# Example


http://itunes.apple.com/us/app/italk-recorder-premium/id<font color="red">296271871</font>?mt=8

<code>
require 'appstore-scraper'

apps = {
  'iTalk' => 296271871,
}

stores = [
	'United States',
	'France',
]

reviews = []
scraper = AppstoreScrapper.new
apps.each_value do |app|
	stores.each do |store|
		scraper.set_store(store)
		reviews << scraper.fetch_reviews(app)
	end
end

pp reviews
</code>
