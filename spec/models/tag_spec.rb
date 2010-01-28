require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  before do
    @embed = create_embed
    @embed.tag_with ["delicious", "sexy"]
  end
  it "shows tags with to_s" do
    @embed.tags(true).to_s.should == "delicious sexy"
  end
  it "shows tags with tag_list" do
    @embed.tag_list.should == "delicious sexy"
  end
end
