require 'unirest'
class FlightsController < ApplicationController

  def create
    from, to = get_places
    arr_carriers=[]
    date=Time.now.strftime("%Y-%m")
    resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/#{from}/#{to}/#{date}",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
    month=Hash.from_xml(resp.body)
    arr_carriers.push(month["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
    month= month["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
    month= month.sort_by{|obj| obj["MinPrice"]}[0..4]
    resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/#{from}/#{to}/anytime",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
    anytime=Hash.from_xml(resp.body)
    arr_carriers.push(anytime["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
    anytime= anytime["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
    anytime= anytime.sort_by{|obj| obj["MinPrice"]}[0..4]
    week, x =fetch_week(from, to)
    arr_carriers.push(x)
    arr_carriers= arr_carriers.flatten.uniq

    render json: { week: week , current_month: month, anytime: anytime, carriers: arr_carriers }
  end


  def fetch_week(from, to)
    current_time = Time.now
    date_addition = 1
    day_arr=[]
    arr_carriers=[]
    7.times do
      tmp_time = current_time + (date_addition * 86400)
      date_addition +=1
      date=tmp_time.strftime("%Y-%m-%d")
      resp= Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/#{from}/#{to}/#{date}",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
      day=Hash.from_xml(resp.body)
      arr_carriers.push(day["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
      if day["BrowseQuotesResponseAPIDto"]["Quotes"] == nil
        day= nil
      else
        day= day["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
      end
      day_arr.push(day)
    end
    arr_carriers= arr_carriers.flatten.uniq
    return day_arr.compact.flatten.sort_by{|obj| obj["MinPrice"]}[0..4], arr_carriers
  end

  def get_places
      to= flight_params["to"]
      from= flight_params["from"]
      resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/autosuggest/v1.0/US/USD/en-US/?query=#{to}" ,  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
      x = Hash.from_xml(resp.body)
      to_place_id= x["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"].first["PlaceId"]
      resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/autosuggest/v1.0/US/USD/en-US/?query=#{from}" ,  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
      x = Hash.from_xml(resp.body)
      from_place_id= x["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"].first["PlaceId"]

      return from_place_id, to_place_id
  end

  private

  def flight_params
    params.permit(:to, :from)
  end
end
