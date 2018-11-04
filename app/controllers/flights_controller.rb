require 'unirest'
class FlightsController < ApplicationController

  def create
    # get current day and add 8. fetch data for each of thiseTime.now.strftime("%m/%d/%Y")
    arr_carriers=[]
    resp= Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/SFO-sky/JFK-sky/2019-01-01",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
    day=Hash.from_xml(resp.body)
    arr_carriers.push(day["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
    day= day["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
    day= day.sort_by{|obj| obj["MinPrice"]}[0..4]
    resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/SFO-sky/JFK-sky/2019-01",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
    month=Hash.from_xml(resp.body)
    arr_carriers.push(month["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
    month= month["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
    month= month.sort_by{|obj| obj["MinPrice"]}[0..4]
    resp=Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/SFO-sky/JFK-sky/anytime",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
    anytime=Hash.from_xml(resp.body)
    arr_carriers.push(anytime["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
    anytime= anytime["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
    anytime= anytime.sort_by{|obj| obj["MinPrice"]}[0..4]
    week, x =fetch_week
    arr_carriers.push(x)
    arr_carriers= arr_carriers.flatten.uniq

    render json: { day: day, month:month, anytime: anytime, carriers:arr_carriers, week:week }
  end


  def fetch_week
    current_time = Time.now
    date_addition = 1
    day_arr=[]
    arr_carriers=[]
    7.times do
      tmp_time = current_time + (date_addition * 86400)
      date_addition +=1
      date=tmp_time.strftime("%Y-%m-%d")
      resp= Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.mashape.com/apiservices/browsequotes/v1.0/US/USD/en-US/SFO-sky/JFK-sky/#{date}",  headers:{"X-Mashape-Key"=>ENV["sky_key"],"X-Mashape-Host"=>"skyscanner-skyscanner-flight-search-v1.p.mashape.com"}, parameters: nil, auth:nil)
      day=Hash.from_xml(resp.body)
      arr_carriers.push(day["BrowseQuotesResponseAPIDto"]["Carriers"]["CarriersDto"])
      day= day["BrowseQuotesResponseAPIDto"]["Quotes"]["QuoteDto"]
      day_arr.push(day)
    end
    arr_carriers= arr_carriers.flatten.uniq
    return day_arr.flatten.sort_by{|obj| obj["MinPrice"]}[0..4], arr_carriers
  end

  private

  def flight_params
    params.permit(:to, :from)
  end
end
