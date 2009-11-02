get "/" do
  mustache :index
end

post "/extract" do
  if !params[:url].empty? && !params[:file_name].empty?
    public = File.join(File.dirname(__FILE__)) + "/public"
    file_name = "/extracted/" + params[:file_name].gsub(/[^a-zA-Z0-9_-]/,'') + ".jpg"
    AmazonZoomExtractor.extract(params[:url], "#{public}#{file_name}")
    redirect file_name
  else
    "Sorry. You have to supply the url and name"
  end
end