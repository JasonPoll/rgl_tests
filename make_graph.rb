#!/usr/bin/env ruby

require 'rgl/adjacency'
require 'rgl/dot'

# graph = RGL::DirectedAdjacencyGraph.new
# graph.add_edge 1,2
# graph.add_edge 3,4
# graph.add_edge 1,4
# graph.add_edge 4,3
#
# graph.print_dotted_on


def neat_data
  {
    "CCI Custom Scripts" => {
      "CachedPropertyUsers(JSON)" => {
        "CachedZDPropertyUsers(Filter)" => "NEATUserAccessible ZDPropertyUsers(SQL)"
      }
    },
    "Zendesk API" => {
      "Zendesk\nOrganizations(JSON)" => {
        "NEATUserAccessible ZDPropertyUsers(SQL)" => {
          "ZD PropertyUser by ID(SQL)" => "Location Details"
        }
      }
    }
  }
end

def test_data
  {
    BaseOdsRecord: [:AdpEmployeeOdsRecord, :AdpManagerOdsRecord, :AdpReportOdsRecord, :AdpStatusOdsRecord, :LaborEstimateVerticalDetail],
    BaseOdsService: [
      :QuickbaseService,
      { ProjectPercentCompleteOdsService: :ProjectPercentCompleteOdsImportService},
      { PodsOdsService: :PodsOdsImportService },
      :OdsManagementService,
      { MasOdsService: [
        { MasTaxOdsService: :TaxImportService },
        :MasJobInfoService,
        :MasCompanyService,
        :LaborEstimatorMasImportService
        ]
      },
      { LaborEstimatorOdsService: [
        :LaborEstimatorSalesforceImportService,
        :LaborEstimatorReportingService,
        :LaborEstimatorMasImportService,
        :LaborEstimatorCacheOdsService
        ]
      },
      { Bid2WinService: [
          :Bid2WinSchemaService,
          { Bid2WinImportService: :Bid2WinReportingService }
        ]
      },
      { AdpEmployeeOdsService: [
        :EmployeeOdsReportingService,
        :AdpEmployeeOdsUpdateService
        ]
      }
    ]
  }
end

# data = { BaseOdsService: [:QuicbaseService, :OdsManagementService, :FooService]}

# graph = RGL::DirectedAdjacencyGraph.new

def build_graph(data, graph = nil)
  graph = RGL::DirectedAdjacencyGraph.new if graph.nil?

  data.each do |k, v|
    puts "k: #{k}\nv: (#{v.class}) #{v}\n\n"

    if v.is_a?(Array)
      v.each do |v2|
        puts "? (#{v2.class}) #{v2}"
        if v2.is_a?(Hash)
          v2.keys.each do |k2|
            puts "  #{k} -> #{k2}"
            graph.add_edge(k.to_s, k2.to_s)
          end
          build_graph(v2, graph)
        else
          puts "  #{k} -> #{v2}"
          graph.add_edge(k.to_s, v2.to_s)
        end
      end
    elsif v.is_a?(Hash)
      v.keys.each do |v2|
        puts "   #{k} -> #{v2}"
        graph.add_edge(k.to_s, v2.to_s)
      end
      build_graph(v, graph)
    else
      puts "   #{k} -> #{v}"
      graph.add_edge(k.to_s, v.to_s)
    end
  end
  graph
end

def build_graph2(data, root = nil, graph = nil)
  graph = RGL::DirectedAdjacencyGraph.new if graph.nil?

  puts "\n\nroot: #{root}"
  if data.is_a?(Hash)
    puts "!!!data is a hash: #{data}"
    data.each do |k,v|
      build_graph2(k, root, graph) if !root.nil?
      build_graph2(v, k, graph)
    end
  elsif data.is_a?(Array)
    puts "!!!data is an array #{data}"
    data.each do |v|
      build_graph2(v, root, graph)
    end
  else
    puts "#{root} -> #{data}"
    graph.add_edge(root.to_s, data.to_s)
  end
  graph
end

# graph = build_graph(data, graph)
# graph.print_dotted_on
# graph.write_to_graphic_file('png')