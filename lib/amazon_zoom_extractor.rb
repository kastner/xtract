require 'open-uri'
require 'fileutils'
require 'forwardable'

class AmazonZoomExtractor
  extend Forwardable

  USER_AGENT = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"
  DYNAPI_FIELDS = %w{max_zoom_level tile_size image_str width height version}

  def_delegators :dynapi_fields, *DYNAPI_FIELDS

  def self.extract(url, big_name="big.jpg")
    az = new(url)
    az.fetch
    az.combine(big_name)
    az.cleanup
  end
  
  def initialize(url)
    @url = url
    puts "Getting #{@url}"
  end
  
  def page
    @page ||= open(@url, "User-Agent" => USER_AGENT).read
  end
  
  def asin
    image_str_fields.first
  end
  
  def ou
    image_str_fields[1].split("-")[0]
  end
  
  def variant
    image_str_fields[2] || "MAIN"
  end
  
  def image_str_fields
    image_str.split("/").last.split(".")
  end
  
  def vip
    image_str.split("/")[2]
  end
  
  def image_urls
    @image_urls ||= begin
      i_urls = []
      tiles_down.times do |y|
        tiles_across.times do |x|
          zoom = "_SCR(#{max_zoom_level},#{x},#{y})_"
          i_urls << image_url % [vip, asin, zoom, ou, 
                                 size, variant, version, extension]
        end
      end
      i_urls
    end
  end
  
  def dynapi_fields
    cap_re = /scaleLevels\[(\d)\]\s=\s
              new\sMediaServicesZoom[^\n]+\s(\d+)\);\s+
              DynAPI.addZoomViewer\("(.+?)",\d+,\d+,(\d+),(\d+),(\d+),/xm
    capture = page.scan(cap_re)[0]
    @dynapi_fields ||= Struct.new(*DYNAPI_FIELDS).new(*capture)
  end
  
  def fetch
    FileUtils.mkdir(tmp_path) rescue Errno::EEXIST
    
    image_urls.each_with_index do |image, i|
      local_image = "#{tmp_path}/%04d.jpg" % i
      %x{curl "#{image}" -o #{local_image}}
    end
  end
  
  def combine(big_name="big.jpg")
    tile = "#{tiles_across}x#{tiles_down}"
    %x{montage #{tmp_path}/*.jpg -tile #{tile} -geometry -0-0 #{big_name}}
    puts "Made #{big_name} from #{@url}"
  end
  
  def cleanup
    Dir["#{tmp_path}/*.jpg"].each { |f| FileUtils.rm(f) }
  end
  
  def tiles_across() (width.to_i/tile_size.to_f).ceil end
  def tiles_down() (height.to_i/tile_size.to_f).ceil end
  def image_url() url = "http://%s/R/1/a=%s+d=%s+o=%s+s=%s+va=%s+ve=%s+e=%s" end
  def extension() ".jpg" end  
  def size() "RMTILE" end
  def tmp_path() "/tmp/imgs-del" end
end

if $0 == __FILE__
  require 'rubygems'
  require 'zlib'
  require 'base64'
  require 'mocha'
  require 'test/unit'
  
  $page_contents = Base64.decode64(DATA.read)
    
  class TestAmazonZoomExtractor < Test::Unit::TestCase
    def setup
      AmazonZoomExtractor.any_instance.stubs(:page).returns($page_contents)
      @az = AmazonZoomExtractor.new("")
    end

    def test_should_have_dyn_api_in_body
      assert_match /DynAPI.addZoomViewer/, @az.page
    end
    
    def test_should_find_zoom_levels
      assert_equal 3, @az.max_zoom_level.to_i
    end
    
    def test_should_find_tile_size
      assert_equal 400, @az.tile_size.to_i
    end
    
    def test_should_find_asin
      assert_equal "B0015T963C", @az.asin
    end
    
    def test_should_find_ou
      assert_equal "01", @az.ou
    end
    
    def test_should_find_variant
      assert_equal "PT01", @az.variant
    end
    
    def test_should_caculate_tiles_across
      assert_equal 6, @az.tiles_across
    end
    
    def test_should_get_list_of_image_urls
      assert_kind_of Array, @az.image_urls
    end
    
    def test_should_get_a_real_image_url
      image_url = "http://z2-ec2.images-amazon.com/R/1/" +
        "a=B0015T963C+d=_SCR(3,0,1)_+o=01+s=RMTILE+va=PT01+ve=230230795+e=.jpg"
      assert_equal image_url, @az.image_urls[6]
    end
  end
end

__END__
CiAgICAgIDx0YWJsZSB3aWR0aD0iNjM1IiBib3JkZXI9IjAiIGFsaWduPSJj
ZW50ZXIiIGNlbGxwYWRkaW5nPSIzIiBjZWxsc3BhY2luZz0iMCIgY2xhc3M9
ImRvdHRlZHRhYmxlIj4KICAgICAgICA8dHI+IAogICAgICAgICAgPHRkPjxk
aXYgaWQ9ImltYWdlUGxhY2VIb2xkZXIiIGFsaWduPSJjZW50ZXIiIHZhbGln
bj0ibWlkZGxlIj4KICAgICAgICAgICAgIDxub3NjcmlwdD48ZGl2IGlkPSJp
bWFnZVZpZXdlckRpdiI+PGltZyBzcmM9Imh0dHA6Ly9lY3guaW1hZ2VzLWFt
YXpvbi5jb20vaW1hZ2VzL0kvNDFSNGVhODRSckwuX1NTMzUwXy5qcGciIGlk
PSJwcm9kSW1hZ2UiIC8+PC9kaXY+PC9ub3NjcmlwdD4KICAgIAoKICAgICAg
ICA8c2NyaXB0IGxhbmd1YWdlPSJqYXZhc2NyaXB0Ij4KICAgICAgICA8IS0t
IAogIHZhciBzY2FsZUxldmVsczsKCgogICAgICBzY2FsZUxldmVscyA9IG5l
dyBBcnJheSg0KTsKCgogICAgICBzY2FsZUxldmVsc1swXSA9IG5ldyBNZWRp
YVNlcnZpY2VzWm9vbVNjYWxlKDYwMCwgNjAwLCA2MDApOwoKICAgICAgc2Nh
bGVMZXZlbHNbMV0gPSBuZXcgTWVkaWFTZXJ2aWNlc1pvb21TY2FsZSgxMDEx
LCAxMDExLCA0MDApOwoKICAgICAgc2NhbGVMZXZlbHNbMl0gPSBuZXcgTWVk
aWFTZXJ2aWNlc1pvb21TY2FsZSgxNTE2LCAxNTE2LCA0MDApOwoKICAgICAg
c2NhbGVMZXZlbHNbM10gPSBuZXcgTWVkaWFTZXJ2aWNlc1pvb21TY2FsZSgy
MDIyLCAyMDIyLCA0MDApOwoKICBEeW5BUEkuYWRkWm9vbVZpZXdlcigiaHR0
cDovL3oyLWVjMi5pbWFnZXMtYW1hem9uLmNvbS9pbWFnZXMvUi9CMDAxNVQ5
NjNDLjAxLlBUMDEiLDM1MCwzNTAsMjAyMiwyMDIyLDIzMDIzMDc5NSwiYW16
dGlsZSIsc2NhbGVMZXZlbHMpOwogICAgICAgIC8vLS0+CiAgICAgICAgPC9z
Y3JpcHQ+CgogICAgICA8ZGl2IGlkPSJpbWFnZVZpZXdlckRpdiI+PC9kaXY+
CiAgICAgICAgICA8L2Rpdj4KICA8L3RkPgogICAgICAgIDwvdGQ+CiAgICAg
IDwvdHI+Cg==