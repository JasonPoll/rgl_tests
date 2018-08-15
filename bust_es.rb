require 'json'
require 'active_support/all'
require 'rgl/adjacency'
require 'rgl/dot'

def talbe_nodes_filename=(val)
  @table_nodes_filename = val
end
def table_nodes_filename
  @table_nodes_filename ||= '/Users/jtpoll/Downloads/LAB_FULL_Edge343_20180710-181000/entities/DataProducerEntityManager-AbstractTabularProducerDO.json'
end

def tabular_nodes_file_data
  @data ||= JSON.parse(File.read(table_nodes_filename)).deep_symbolize_keys
end

# * Fugly massive PNG?  Gimp can view it.
# https://dreampuf.github.io/GraphvizOnline/ is your friend for validating/viewing .dot files.
# graphit().write_to_graphic_file('png')
# graphit().print_dotted_on

# 1: get the visualization and connection info into the data_feeds/tabular_transforms format, and feed them into graphit().
# 2: Start from visualizations, and graph backwards.
# 2.1: Graph individual/sets-of visualizations in order to drill-in.
# 3: get pages, listing visualizations found on them.
# 3.1 use to identify orphaned visualizations
# 3.2 use to identify dead areas of the pipeline for cleanup

# weird_ones = tabular_transforms_raw.map{|h| [h[:properties][:propertyValues].find{|h2| h2[:propertyDefName] == 'name'}[:value], h[:properties][:propertyValues].find{|h2| h2[:propertyDefName] == 'attributes'}]}.select{|a| a.second.nil?}
# => [["LM Device Group Map by Customer", nil], ["Open Tickets by Org", nil], ["ZenDesk Ticket Staus Count", nil], ["LM Nomadix Devices by Device Group ID", nil]]
def tabular_transforms_raw
  tabular_nodes_file_data[:objects].select{|h| h[:doClass] == 'TabularTransformDO'}
end
def tabular_transforms
  @tabulate_transforms ||= tabular_transforms_raw.map do |h|
    {
      id: h[:id],
      name: feed_name(h),
      type_name: h[:typeName],
      upstream_ids: h[:upstreamConstructIds],
      parameters: h[:parameters].map{|h2| h2[:parameterName]},
      outputs: attribute_defs(h)
    }
  end
end

def data_feeds_raw
  tabular_nodes_file_data[:objects].select{|h| h[:doClass] == 'DataFeedDO'}
end
def data_feeds
  @data_feeds ||= data_feeds_raw.map do |h|
    {
      id: h[:id],
      name: feed_name(h),
      type_name: h[:typeName],
      upstream_ids: h[:upstreamConstructIds],
      parameters: h[:parameters].map{|h2| h2[:parameterName]},
      outputs: attribute_defs(h)
    }
  end
end

def graphit
  graph = RGL::DirectedAdjacencyGraph.new

  graph = grind_hash(data_feeds, graph)
  graph = grind_hash(tabular_transforms, graph)

  graph
end


def grind_hash(h, graph)
  h.each do |child|
    input_feeds = data_feeds.select{|parent| child[:upstream_ids].include?(parent[:id])}
    input_feeds += tabular_transforms.select{|parent| child[:upstream_ids].include?(parent[:id])}

    if input_feeds.empty?
      graph.add_edge(child[:upstream_ids].join(","), edge_text(child))
    else
      input_feeds.each do |parent|
        graph.add_edge(edge_text(parent), edge_text(child))
      end
    end
  end

  graph
end

def edge_text(h)
  "#{h[:name]}(#{h[:parameters].join(',')})\\n[#{h[:outputs].join(',')}]"
end

def feed_name(h)
   h[:properties][:propertyValues].find{|h2| h2[:propertyDefName] == 'name'}[:value]
end

def attribute_defs_raw(h)
  (h[:properties][:propertyValues].find{|h2| h2[:propertyDefName] == 'attributes'} || {value: {selectedAttributeList: []}.to_json})[:value]
end

def attribute_defs(h)
  JSON.parse(attribute_defs_raw(h)).deep_symbolize_keys[:selectedAttributeList].map{|h2| h2[:newAttributeName] || h2[:attributeName]}
end