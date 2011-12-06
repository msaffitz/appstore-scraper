#
# appstore_reviews
#
#  Fetch iTunes App Store reviews for each application, across all country stores, with translation
#   -- reads rating, author, subject and review body
#
# Notes
#  Derived from Erica Sadun's scraper: http://blogs.oreilly.com/iphone/2008/08/scraping-appstore-reviews.html
#  Apple's XML is purely layout-based, without much semantic relation to reviews, so the CSS paths below
#   are brittle.
#
# Jeremy Wohl
#   relevant post: http://igmus.org/2008/09/fetching-app-store-reviews
#
# TODO: spider additional review pages
# TODO: add option for latest version only: &onlyLatestVersion=true

require 'rubygems'
require 'hpricot'
require 'httparty'

class AppstoreScrapper

	module SortOrders
		MOST_HELPFUL = 4
		MOST_FAVORABLE = 2
		MOST_CRITICAL = 3
		MOST_RECENT = 0
	end

	USER_AGENT_HEADER = 'iTunes/9.2 (Macintosh; U; Mac OS X 10.6'
	TRANSLATE_URL = 'http://ajax.googleapis.com/ajax/services/language/translate?'
	APP_STORE_URL = 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews'
	STORE_TYPE = 'Purple+Software'
	DEFAULT_NATIVE_LANGUAGE = 'en'
	DEFAULT_STORE = 'United States'
	
	attr_accessor :native_language, :should_translate, :sort_order

	@@stores = [
			{ :name => 'United States',        :id => 143441, :language => 'en'    },
			{ :name => 'Argentina',            :id => 143505, :language => 'es'    },
			{ :name => 'Australia',            :id => 143460, :language => 'en'    },
			{ :name => 'Belgium',              :id => 143446, :language => 'nl'    },
			{ :name => 'Brazil',               :id => 143503, :language => 'pt'    },
			{ :name => 'Canada',               :id => 143455, :language => 'en'    },
			{ :name => 'Chile',                :id => 143483, :language => 'es'    },
			{ :name => 'China',                :id => 143465, :language => 'zh-CN' },
			{ :name => 'Colombia',             :id => 143501, :language => 'es'    },
			{ :name => 'Costa Rica',           :id => 143495, :language => 'es'    },
			{ :name => 'Croatia',              :id => 143494, :language => 'hr'    },
			{ :name => 'Czech Republic',       :id => 143489, :language => 'cs'    },
			{ :name => 'Denmark',              :id => 143458, :language => 'da'    },
			{ :name => 'Deutschland',          :id => 143443, :language => 'de'    },
			{ :name => 'El Salvador',          :id => 143506, :language => 'es'    },
			{ :name => 'Espana',               :id => 143454, :language => 'es'    },
			{ :name => 'Finland',              :id => 143447, :language => 'fi'    },
			{ :name => 'France',               :id => 143442, :language => 'fr'    },
			{ :name => 'Greece',               :id => 143448, :language => 'el'    },
			{ :name => 'Guatemala',            :id => 143504, :language => 'es'    },
			{ :name => 'Hong Kong',            :id => 143463, :language => 'zh-TW' },
			{ :name => 'Hungary',              :id => 143482, :language => 'hu'    },
			{ :name => 'India',                :id => 143467, :language => ''      },
			{ :name => 'Indonesia',            :id => 143476, :language => ''      },
			{ :name => 'Ireland',              :id => 143449, :language => ''      },
			{ :name => 'Israel',               :id => 143491, :language => ''      },
			{ :name => 'Italia',               :id => 143450, :language => 'it'    },
			{ :name => 'Korea',                :id => 143466, :language => 'ko'    },
			{ :name => 'Kuwait',               :id => 143493, :language => 'ar'    },
			{ :name => 'Lebanon',              :id => 143497, :language => 'ar'    },
			{ :name => 'Luxembourg',           :id => 143451, :language => 'de'    },
			{ :name => 'Malaysia',             :id => 143473, :language => ''      },
			{ :name => 'Mexico',               :id => 143468, :language => 'es'    },
			{ :name => 'Nederland',            :id => 143452, :language => 'nl'    },
			{ :name => 'New Zealand',          :id => 143461, :language => 'en'    },
			{ :name => 'Norway',               :id => 143457, :language => 'no'    },
			{ :name => 'Osterreich',           :id => 143445, :language => 'de'    },
			{ :name => 'Pakistan',             :id => 143477, :language => ''      },
			{ :name => 'Panama',               :id => 143485, :language => 'es'    },
			{ :name => 'Peru',                 :id => 143507, :language => 'es'    },
			{ :name => 'Phillipines',          :id => 143474, :language => ''      },
			{ :name => 'Poland',               :id => 143478, :language => 'pl'    },
			{ :name => 'Portugal',             :id => 143453, :language => 'pt'    },
			{ :name => 'Qatar',                :id => 143498, :language => 'ar'    },
			{ :name => 'Romania',              :id => 143487, :language => 'ro'    },
			{ :name => 'Russia',               :id => 143469, :language => 'ru'    },
			{ :name => 'Saudi Arabia',         :id => 143479, :language => 'ar'    },
			{ :name => 'Schweiz/Suisse',       :id => 143459, :language => 'auto'  },
			{ :name => 'Singapore',            :id => 143464, :language => ''      },
			{ :name => 'Slovakia',             :id => 143496, :language => ''      },
			{ :name => 'Slovenia',             :id => 143499, :language => ''      },
			{ :name => 'South Africa',         :id => 143472, :language => 'en'    },
			{ :name => 'Sri Lanka',            :id => 143486, :language => ''      },
			{ :name => 'Sweden',               :id => 143456, :language => 'sv'    },
			{ :name => 'Taiwan',               :id => 143470, :language => 'zh-TW' },
			{ :name => 'Thailand',             :id => 143475, :language => 'th'    },
			{ :name => 'Turkey',               :id => 143480, :language => 'tr'    },
			{ :name => 'United Arab Emirates', :id => 143481, :language => ''      },
			{ :name => 'United Kingdom',       :id => 143444, :language => 'en'    },
			{ :name => 'Venezuela',            :id => 143502, :language => 'es'    },
			{ :name => 'Vietnam',              :id => 143471, :language => 'vi'    },
			{ :name => 'Japan',                :id => 143462, :language => 'ja'    },
			{ :name => 'Dominican Republic',   :id => 143508, :language => 'es'    },
			{ :name => 'Ecuador',              :id => 143509, :language => 'es'    },
			{ :name => 'Egypt',                :id => 143516, :language => ''      },
			{ :name => 'Estonia',              :id => 143518, :language => 'et'    },
			{ :name => 'Honduras',             :id => 143510, :language => 'es'    },
			{ :name => 'Jamaica',              :id => 143511, :language => ''      },
			{ :name => 'Kazakhstan',           :id => 143517, :language => ''      },
			{ :name => 'Latvia',               :id => 143519, :language => 'lv'    },
			{ :name => 'Lithuania',            :id => 143520, :language => 'lt'    },
			{ :name => 'Macau',                :id => 143515, :language => ''      },
			{ :name => 'Malta',                :id => 143521, :language => 'mt'    },
			{ :name => 'Moldova',              :id => 143523, :language => ''      },
			{ :name => 'Nicaragua',            :id => 143512, :language => 'es'    },
			{ :name => 'Paraguay',             :id => 143513, :language => 'es'    },
			{ :name => 'Uruguay',              :id => 143514, :language => 'es'    }
	]
	
	def initialize 
		@store = DEFAULT_STORE
		@native_language = DEFAULT_NATIVE_LANGUAGE
		@should_translate = true
		@sort_order = SortOrders::MOST_RECENT
	end

	def store
		@store
	end
	
	def store=(store_name)
		store_hash = @@stores.select{ |s| s[:name] == store_name }.first
		if store_hash.nil?
			abort("App Store \"#{store_name}\" Not In List, Check Spelling")
		else
			@store = store_hash
		end
	end
	
	def fetch_reviews(software_id)
		reviews = []
		begin
			xml = fetch_xml(software_id)
			path = 'Document > View > ScrollView > VBoxView > View > MatrixView > VBoxView:nth(0) > VBoxView > VBoxView'
			xml.search(path).each do |element|
				review = parse_review(element)
				review = translate_review(review) if @should_translate
				reviews << review
			end
			reviews
		rescue => e
			raise e.message
		end
	end
	
	private
	
	def fetch_xml(software_id)
		raw_xml = %x[curl -s -A "#{USER_AGENT_HEADER}" -H "X-Apple-Store-Front: #{@store[:id]}-1" \
					"#{APP_STORE_URL}?id=#{software_id}&pageNumber=0&sortOrdering=#{@sort_order}&type=#{STORE_TYPE}" \
					| xmllint --format --recover - 2>/dev/null]
		raise 'xml request failed' if $? != 0
		xml = Hpricot.XML(raw_xml)
	end
	
	def parse_review(xml_element)
		review = {}
		strings = (xml_element/:SetFontStyle)
		meta    = strings[2].inner_text.split(/\n/).map { |x| x.strip }
		
		# Note: Translate is sensitive to spaces around punctuation, so we make sure br's connote space.
		review[:rating]  = xml_element.inner_html.match(/alt="(\d+) star(s?)"/)[1].to_i
		review[:author]  = meta[3]
		review[:version] = meta[7][/Version (.*)/, 1] unless meta[7].nil?
		review[:date]    = meta[10]
		review[:subject] = strings[0].inner_text.strip
		review[:body]    = strings[3].inner_html.gsub("<br />", "\n").strip
		review
	end
	
	def translate_review(review)
		review[:subject] = translate( :from => @store[:language], :to => @native_language, :text => review[:subject] )
		review[:body]    = translate( :from => @store[:language], :to => @native_language, :text => review[:body] )
	end
	
	def translate(opts)
		from = opts[:from] == 'auto' ? '' : opts[:from] 
		to   = opts[:to]
		result = HTTParty.get(TRANSLATE_URL, :query => { :v => '1.0', :langpair => "#{from}|#{to}", :q => opts[:text] })
		raise result['responseDetails'] if result['responseStatus'] != 200
		return result['responseData']['translatedText']
	end

end

