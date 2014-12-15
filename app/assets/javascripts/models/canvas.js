function Canvas(ctx) {
    this.ctx = ctx
}
var canvasProto = Canvas.prototype

canvasProto.drawRectangle = function(center_x, center_y, width, height, color) {
    var x = center_x - width/2
    var y = center_y - height/2

    this.ctx.fillStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    this.ctx.fillRect(x, y, width, height);
}
canvasProto.drawRectangleByCorners = function(nw_x, nw_y, se_x, se_y) {
    var width = se_x - nw_x
    var height = se_y - nw_y

    this.ctx.beginPath()
    this.ctx.rect(nw_x, nw_y, width, height);
    this.ctx.lineWidth = 1;
    this.ctx.strokeStyle = 'black';
    this.ctx.stroke()

}
canvasProto.drawLine = function(x1, y1, x2, y2, dashed_line_size, line_width, color) {
    this.ctx.beginPath();
    var old_dashed_line_size = this.ctx.getLineDash()
    this.ctx.setLineDash([dashed_line_size])
    this.ctx.lineWidth = line_width || 1
    this.ctx.strokeStyle = color || 'black'
    this.ctx.moveTo(x1, y1);
    this.ctx.lineTo(x2, y2);
    this.ctx.stroke();
    this.ctx.setLineDash(old_dashed_line_size)
}


canvasProto.drawCircle = function(x, y, radius, color) {
    this.ctx.beginPath();
    this.ctx.arc(x, y, radius, 0 , 2 * Math.PI, false);
    this.ctx.strokeStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    this.ctx.fillStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    this.ctx.fill();this.ctx.stroke();
    this.ctx.closePath();
}
canvasProto.drawEllipse = function(x, y, a, b, angle_degrees, color, line_color) {
    var scaling = b/a;

    var angle_radianes = angle_degrees * Math.PI/180;

    function calc_translation_shifts(x, y, angle) {
        var hypotenuse = Math.sqrt(x*x+y*y);
        var beta = Math.atan(y/x);
        var alpha = (angle - beta);
        var y_shift = hypotenuse * Math.sin(-alpha);
        var x_shift = hypotenuse * Math.cos(alpha);
        return {x: x_shift, y: y_shift};
    }


    this.ctx.beginPath();
    this.ctx.save();

    this.ctx.rotate(angle_radianes);

    var shifts = calc_translation_shifts(x, y, angle_radianes);
    this.ctx.translate(shifts.x,shifts.y);

    this.ctx.scale(1, scaling);
    this.ctx.arc(0, 0, a, 0 , 2 * Math.PI, false);
    this.ctx.fillStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    this.ctx.fill();
    this.ctx.lineWidth = 1;
    this.ctx.strokeStyle = line_color;
    this.ctx.stroke();

    this.ctx.restore();
    this.ctx.closePath();
}

canvasProto.drawText = function(x, y, text, size, color) {
    this.ctx.beginPath();
    this.ctx.font = size + 'px Arial';
    this.ctx.fillStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    this.ctx.fillText(text, x, y);
    this.ctx.closePath();
}