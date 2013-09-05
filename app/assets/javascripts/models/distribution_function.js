function DistributionFunction(algorithms) {
    this.algorithms = algorithms

    this.heights = undefined

    this.cdf_plot = undefined
    this.pdf_plot = undefined

    this.lines_options = [
        {color : 'rgba(0, 255, 0, 0.8)', lineWidth: 1, dashPattern: [25,5], symbol : 'triangle'},
        {color : 'rgba(0, 0, 255, 0.8)', lineWidth: 3, dashPattern: [15,4], symbol : 'cross'},
        {color : 'rgba(255, 0, 0, 0.8)', lineWidth: 6, dashPattern: [4,4], symbol : 'diamond'},
        {color : 'black', lineWidth: 2, dashPattern: [1,0], symbol : 'square'},
        {color : 'rgba(255, 0, 255, 0.8)', lineWidth: 3, dashPattern: [5,3], symbol : 'diamond'},

        {color : 'grey', lineWidth: 3, dashPattern: [3,3], symbol : 'circle'}
    ]

    this.labelFormatter = function(label, series) {
        return '<span style="font-size:18px;">' + label + '</span>';
    }

    this.cdf_options = {
        legend: {show: true, position: 'se', labelFormatter: this.labelFormatter},
        yaxis: {min:0, max:1, ticks: 10, axisLabel: 'P', axisLabelUseCanvas: true},
        xaxis: {min:0, max:100, ticks: 20, axisLabel: 'mean error, cm', axisLabelUseCanvas: false}
    }
    this.pdf_options = {
        legend: {show: true, position: 'ne', labelFormatter: this.labelFormatter},
        bars: { show: true, barWidth: 5, fill: 0.4 },
        yaxis: {min:0, ticks: 10, axisLabelUseCanvas: true, tickLength: null},
        xaxis: {min:0, max:150, ticks: 20, axisLabel: 'mean error, cm', axisLabelUseCanvas: false}
    }

    this.points_data_options = function(line_id) {
        return {
            show: false,
            radius: 2,
            symbol: this.lines_options[line_id].symbol,
            fill: false
        }
    }


    this.pdf_states = ['diagram', 'kernel_pdf', 'histogram']
    this.current_pdf_state = undefined
}
var distributionFunctionProto = DistributionFunction.prototype






distributionFunctionProto.plotCdf = function(div_id) {
    var data = []

    var line_id = 0
    for(var algorithm_name in this.algorithms) {
        if(line_id >= this.lines_options.length)line_id = 0

        var cdf = this.algorithms[algorithm_name]['cdf'][this.heights.train][this.heights.test]

        cdf.push([500, 1])
        data.push(
            {
                data: cdf,
                label: algorithm_name,
                color: this.lines_options[line_id].color,
                points: this.points_data_options(line_id),

                lines: {
                    show: true,
                    lineWidth: this.lines_options[line_id].lineWidth,
                    dashPattern: this.lines_options[line_id].dashPattern
                }
            }
        )
        line_id++
    }

    this.cdf_plot = $.plot(div_id, data, this.cdf_options)
}














distributionFunctionProto.plotPdf = function(div_id, state) {
    this.current_pdf_state = state || this.pdf_states[0]
    var pdf_function_type = 'plot' + this.current_pdf_state.split('_').map(
        function(str){ return str.capitalize() }
    ).join('')
    this[pdf_function_type](div_id)
}

distributionFunctionProto.changePdfState = function(div_id) {
    var state = this.current_pdf_state
    var new_state = undefined
    for(var i = 0; i < this.pdf_states.length; i += 1) {
        if(state == this.pdf_states[i]) {
            if(i >= (this.pdf_states.length - 1))new_state = this.pdf_states[0]
            else new_state = this.pdf_states[i + 1]
            break
        }
    }

    this.plotPdf(div_id, new_state)
}



distributionFunctionProto.plotHistogram = function(div_id) {
    this.pdf_options.yaxis.show = true
    this.pdf_options.yaxis.axisLabel = 'N'
    this.pdf_options.yaxis.max = 35
    this.pdf_options.yaxis.ticks = 10
    this.pdf_options.yaxis.tickLength = null


    var data = []

    var line_id = 0
    for(var algorithm_name in this.algorithms) {
        if(line_id >= this.lines_options.length)line_id = 0

        data.push(
            {
                data: this.algorithms[algorithm_name]['pdf'][this.heights.train][this.heights.test],
                label: algorithm_name,
                color: this.lines_options[line_id].color,
                points: this.points_data_options(line_id),
                bars: {
                    show: true,
                    lineWidth: this.lines_options[line_id].lineWidth,
                    dashPattern: this.lines_options[line_id].dashPattern
                },
                lines: {show: false}

            }
        )
        line_id++
    }

    this.pdf_plot = $.plot(div_id, data, this.pdf_options)
}




distributionFunctionProto.plotDiagram = function(div_id) {
    var self = this

    var plot_height = 35
    var padding = undefined
    var algorithms_count = this.algorithms.keys_length()
    if(algorithms_count == 1)padding = 0.0
    else padding = 0.5 + 0.1 * plot_height / algorithms_count / (algorithms_count - 1)
    var box_height = 0.9 * (plot_height - ((algorithms_count - 1) * padding) ) / algorithms_count

    if(box_height > 0.2 * plot_height) {
        box_height = 0.2 * plot_height
    }

    var y = (plot_height + (box_height * algorithms_count + padding * (algorithms_count - 1))) / 2

    this.pdf_options.yaxis.show = true
    this.pdf_options.yaxis.axisLabel = false
    this.pdf_options.yaxis.ticks = []
    this.pdf_options.yaxis.max = plot_height
    this.pdf_options.yaxis.tickLength = 0
    for(var algorithm_name in this.algorithms) {
        this.pdf_options.yaxis.ticks.push([y - box_height / 2, algorithm_name])
        y -= box_height + padding
    }
    this.pdf_plot = $.plot(div_id, [{}], this.pdf_options)
    var canvas = new Canvas(this.pdf_plot.getCanvas().getContext("2d"))
    var offset = this.pdf_plot.getPlotOffset()

    y = (plot_height + (box_height * algorithms_count + padding * (algorithms_count - 1))) / 2

    for(var algorithm_name in this.algorithms) {
        function x_p2c(point) {return (offset.left + self.pdf_plot.getXAxes()[0].p2c(point))}
        function y_p2c(point) {return (offset.top + self.pdf_plot.getYAxes()[0].p2c(point))}

        var errors_parameters = this.algorithms[algorithm_name]['errors_parameters'][this.heights.train][this.heights.test]['total']
        var quartile1 = x_p2c(errors_parameters['quartile1'])
        var mean = x_p2c(errors_parameters['mean'])
        var median = x_p2c(errors_parameters['median'])
        var quartile3 = x_p2c(errors_parameters['quartile3'])
        var percentile10 = x_p2c(errors_parameters['percentile10'])
        var percentile90 = x_p2c(errors_parameters['percentile90'])

        var black_color = [0, 0, 0, 1.0]



        var y_top = y_p2c(y)
        var y_center = y_p2c(y - box_height / 2)
        var y_bottom = y_p2c(y - box_height)

        for(var i in errors_parameters['before_percentile10'])
            canvas.drawCircle(x_p2c(errors_parameters['before_percentile10'][i]), y_center, 2, black_color)
        for(var j in errors_parameters['above_percentile90'])
            canvas.drawCircle(x_p2c(errors_parameters['above_percentile90'][j]), y_center, 2, black_color)

        canvas.drawLine(percentile10, (y_center + y_top) / 2, percentile10, (y_center + y_bottom) / 2)
        canvas.drawLine(percentile10, y_center, quartile1, y_center, 3)
        canvas.drawRectangleByCorners(quartile1, y_top, median, y_bottom)
        canvas.drawLine(mean, y_top, mean, y_bottom, 4, 3)
        canvas.drawLine(median, y_top, median, y_bottom, 0, 2)
        canvas.drawRectangleByCorners(median, y_top, quartile3, y_bottom)
        canvas.drawLine(quartile3, y_center, percentile90, y_center, 3)
        canvas.drawLine(percentile90, (y_center + y_top) / 2, percentile90, (y_center + y_bottom) / 2)

        y -= box_height + padding
    }

}



distributionFunctionProto.plotKernelPdf = function(div_id) {
    var self = this
    var max = 0.0

    function kernel_pdf_value(x, sigma) {
        var sum = 0.0
        var errors = self.algorithms[algorithm_name]['errors'][self.heights.train][self.heights.test]
        for(var i in errors) {
            sum += Math.exp(- Math.pow((x - errors[i]), 2) / (2 * Math.pow(sigma, 2)))
        }
        return sum / (errors.length * sigma * Math.sqrt(2 * Math.PI))
    }


    this.pdf_options.yaxis.show = true
    this.pdf_options.yaxis.axisLabel = 'P'
    this.pdf_options.yaxis.ticks = 10
    this.pdf_options.yaxis.tickLength = null

    var data = []

    var line_index = 0
    for(var algorithm_name in this.algorithms) {
        if(line_index >= this.lines_options.length)line_index = 0

        var current_data = {
            data: [],
            label: algorithm_name,
            color: this.lines_options[line_index].color,
            points: this.points_data_options(line_index),
            lines: {
                show: true,
                lineWidth: this.lines_options[line_index].lineWidth,
                dashPattern: this.lines_options[line_index].dashPattern
            },
            bars: {show: false}
        }

        var sigma = this.algorithms[algorithm_name]['errors_parameters'][this.heights.train][this.heights.test]['total']['stddev']

        for(var x = 0; x < this.pdf_options.xaxis.max; x += 1) {
            var y = kernel_pdf_value(x, sigma)
            if(y > max)max = y
            current_data.data.push([x, y])
        }

        data.push(current_data)
        line_index++
    }
    this.pdf_options.yaxis.max = max + 0.1 * max

    this.pdf_plot = $.plot(div_id, data, this.pdf_options)
}