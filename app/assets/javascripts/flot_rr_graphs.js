var rr_graphs_data = {}

function startRRGraphPlotting() {
    for(var graph_div_id in rr_graphs_data) {
        plotRRGraph('#'+graph_div_id, rr_graphs_data[graph_div_id])
    }



    function plotRRGraph(id, rr_input) {
        var graph_data = []

        var lines = [
            {color : 'red', lineWidth: 2, dashPattern: [3,3], symbol : 'square'},
            {color : 'green', lineWidth: 2, dashPattern: [15,5], symbol : 'triangle'},
            {color : 'blue', lineWidth: 2, dashPattern: [6,6], symbol : 'cross'},
            {color : 'purple', lineWidth: 5, dashPattern: [3,3], symbol : 'diamond'},
            {color : 'black', lineWidth: 5, dashPattern: [1,0], symbol : 'circle'}
        ]

        var line_id = 0
        for(var index in rr_input) {
            if(line_id >= lines.length)line_id = 0

            graph_data.push(
                {
                    data: rr_input[index],
                    label: index,
                    lines: {show: true},
                    points: {show: true, radius: 2, symbol: lines[line_id].symbol, fill: false}
                }
            )

            line_id++
        }


        var options = {
            legend: {
                show: true,
                position: 'se',
                labelFormatter: function(label, series) {
                    return '<span style="font-size:18px;">' + label + '</span>';
                }
            },
            yaxis: {min:0, max:1, ticks: 10, axisLabel: 'RR', axisLabelUseCanvas: true},
            xaxis: {min:-300, max:300, ticks: 20, axisLabel: 'distance, cm', axisLabelUseCanvas: false}
        }


        $.plot(id, graph_data, options);
    }

}