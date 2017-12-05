var w = 500,
    h = 500,
    pad = 20,
    left_pad = 50,
    Data_url = '/data.json',
    initialised = 0,
    aps,
    fps,
    palette,
    colourmap = {},
    showMeta = 0,
    colZon =0,
    showCube = 0;
    
    
    // colorbrewer scales @ https://bl.ocks.org/mbostock/5577023
    // and http://colorbrewer2.org/
    
Shiny.addCustomMessageHandler("parameters", function(message) {aps = Number(message[0]), fps = Number(message[1])});

var duration = 1000 / 1;
var width = w-pad-left_pad;

var svg = d3.select("#d3_output_2")
    .append("svg")
    .attr("width", w)
    .attr("height", h);

var x = d3.scale.linear().domain([-1, 1]).range([left_pad, w - pad]),
    y = d3.scale.linear().domain([-1, 1]).range([pad, h - pad * 2]);
    
var colorScale = d3.scale.linear()
  .domain([-1, 0, 1])
  .range(["#FFFFDD", "#3E9583", "#1F2D86"]);

d3.select(window).on('resize', resize); 

function resize() {
    // update width
    width = parseInt(d3.select('#d3_output_2').style('width'), 10);
    height = parseInt(d3.select('#d3_output_2').style('height'), 10);
    
    svg.attr("width", width).attr("height", height);
    
    // reset x range
    x.range([left_pad, width - pad]);
    y.range([pad,height - pad * 2]);

    // do the actual resize...
}
//var xCenter = (w - left_pad)/2;
//var yCenter = ((h-pad*2) - pad)/2;

var xAxis = d3.svg.axis().scale(x).orient("bottom")
    .ticks(10);

var yAxis = d3.svg.axis().scale(y).orient("left")
    .ticks(10);

var mySymbols = ["diamond","square","triangle-down", "triangle-up"];

svg.append("g")
    .attr("class", "axis")
    .attr("transform", "translate(0, " + (h - pad) + ")")
    .call(xAxis);

svg.append("g")
    .attr("class", "axis")
    .attr("transform", "translate(" + (left_pad - pad) + ", 0)")
    .call(yAxis);

svg.append("text")
    .attr("class", "loading")
    .text("Loading ...")
    .attr("x", function() {
        return w / 2;
    })
    .attr("y", function() {
        return h / 2 - 5;
    });

Shiny.addCustomMessageHandler("info",
  function (message) {
    document.getElementById('info').innerHTML = message;
  }
)


Shiny.addCustomMessageHandler("debug",
  function (message){
    document.getElementById('d3_output').innerHTML = message;
  })

Shiny.addCustomMessageHandler("newcolours",
function(message) {
  
  svg.selectAll(".legend1").remove();

  draw_legend = function(message) {
          var legend = svg.selectAll(".legend1")
      .data(message)
    .enter().append("g")
      .attr("class", "legend1")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });
      
       // draw legend colored rectangles
  legend.append("rect")
      .attr("x", w - 18)
      .attr("width", 18)
      .attr("height", 18)
      .style("fill", function(d) {
        return colourmap[d]
      });
      
      
      legend.append("text")
      .attr("x", w - 24)
      .attr("y", 9)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function(d) { return d;});
      
        }
  
  l = message.length
  palette = d3.scaleOrdinal(d3.schemeDark2);
  
  for (i = 0; i < l; i++) {
    colourmap[message[i]] = palette(i); // for discrete palettes
    // colourmap[message[i]] = palette((i+1)/(l+1)); // for continuous palettes
    }
    
    draw_legend(message);
  
}
)

Shiny.addCustomMessageHandler("colZ", function(message){
  // this is based on http://bl.ocks.org/nbremer/62cf60e116ae821c06602793d265eaf6
  
  svg.selectAll(".legend1").remove();
  svg.selectAll(".legendWrapper").remove();
  
  colorScale
    .domain(d3.range(message.cMin, message.cMax, message.cDiff / (6)))
    .range(['#88419d', '#8c6bb1', '#8c96c6', '#9ebcda', '#bfd3e6', "#fec44f"])
    //.range(['#800026', '#bd0026', '#e31a1c', '#fc4e2a', '#fd8d3c', '#feb24c', '#fed976', '#ffeda0', '#ffffcc'])
  	//.domain(d3.range(message.cMin, message.cMax, message.cDiff / (9)))
  	//.range(['#081d58', '#253494', '#225ea8', '#1d91c0', '#41b6c4', '#7fcdbb', '#c7e9b4', '#edf8b1', '#ffffd9']);
  	
  var countScale = d3.scale.linear()
	.domain([message.cMin, message.cMax])
	.range([0, width])
	
	//Calculate the variables for the temp gradient
  var numStops = 10;
  countRange = countScale.domain();
  countRange[2] = countRange[1] - countRange[0];
  countPoint = [];
  for(var i = 0; i < numStops; i++) {
	  countPoint.push(i * countRange[2]/(numStops-1) + countRange[0]);
  }//for i

  //Create the gradient
  svg.append("defs")
	  .append("linearGradient")
  	.attr("id", "legend-traffic")
	  .attr("x1", "0%").attr("y1", "0%")
  	.attr("x2", "100%").attr("y2", "0%")
  	.selectAll("stop") 
  	.data(d3.range(numStops))                
  	.enter().append("stop") 
  	.attr("offset", function(d,i) { 
	  	return countScale( countPoint[i] )/width;
  	})   
	  .attr("stop-color", function(d,i) { 
	  	return colorScale( countPoint[i] ); 
  	});
  	
  var legendWidth = Math.min(width*0.8, 400);
  //Color Legend container
  var legendsvg = svg.append("g")
	  .attr("class", "legendWrapper")
	  .attr("transform", "translate(" + (width/2) + "," + (h-50) + ")");

  //Draw the Rectangle
  legendsvg.append("rect")
  	.attr("class", "legendRect")
  	.attr("x", -legendWidth/2)
  	.attr("y", 0)
  	//.attr("rx", hexRadius*1.25/2)
  	.attr("width", legendWidth)
  	.attr("height", 10)
  	.style("fill", "url(#legend-traffic)");
	
  //Append title
  legendsvg.append("text")
  	.attr("class", "legendTitle")
  	.attr("x", 0)
  	.attr("y", -10)
  	.style("text-anchor", "middle")
  	.text(message.n);

  //Set scale for x-axis
  var xScale = d3.scale.linear()
  	 .range([-legendWidth/2, legendWidth/2])
  	 //.domain([68,100]);
  	 .domain([ message.cMin, message.cMax] );
  	 
  	// document.getElementById('d3_output').innerHTML = xScale(90);
 
   legendsvg.selectAll(".tagText")
     .data(message.l)
     .enter().append("text")
  	 .attr("class", ".tagText")
  	  .attr("x", function(d){return xScale(d);})
    	 .attr("y", 25)
  	  .style("text-anchor", "middle")
    	.text(function(d){return String(d);});
 
  //Define x-axis
  var legxAxis = d3.svg.axis()
	    .orient("bottom")
	    //.ticks(3)
	    //.tickSize(6)
	    //.tickFormat(formatPercent)
	    .scale(xScale);
	    

  //Set up X axis
  legendsvg.append("g")
	  //.attr("class", "axis")
	  //.attr("x",0)
	  //.attr("y", -10)
	  //.attr("transform", "translate(" + (-legendWidth/2) + "," + 0 + ")")
	  .call(legxAxis);
})


Shiny.addCustomMessageHandler("cube",
  function(message) {
    showCube = Number(message[0]);
  }
)

Shiny.addCustomMessageHandler("colZon",
  function(message) {
    colZon = Number(message[0]);
  }
)

Shiny.addCustomMessageHandler("metadata",
  function(message) {
    svg.selectAll(".legend2").remove();
    showMeta = Number(message.s[0]);
    if(showMeta==1){
      //from https://stackoverflow.com/questions/42653634/how-can-i-use-symbols-with-a-legend
      var legendMeta = svg.append('g')
    .attr("class", "legend2")
    .attr("height", 0)
    .attr("width", 0)
    .attr('transform', 'translate(20,20)');

  var legendRect = legendMeta
    .selectAll('g')
    .data(message.l);

  var legendRectE = legendRect.enter()
    .append("g")
    .attr("transform", function(d,i){
      return 'translate(0, ' + (i * 20) + ')';
    });
    
  legendRectE
      .append('path')
      .attr("d", d3.svg.symbol().type((d) => { return mySymbols[d.i-1] })) 
        .style("fill", "black");

  legendRectE
    .append("text")
    .attr("x", 10)
    .attr("y", 5)
    .text(function (d) {
        return d.n;
    });
    }
  }
)

Shiny.addCustomMessageHandler("data",
    function(message) {
        

        
        draw_metadata = function(message) {
        
          svg.selectAll(".path2")
          .data(message.m)
          .enter().append("path")
          .attr("class", "path2")
          .attr("transform", function(d) { return "translate(" + x(d.x) + "," + y(d.y) + ")"; })
          .attr("d", d3.svg.symbol().type( function(d) {
            return mySymbols[d.i]; })
            .size(7*7))
          .attr("r",2)
          .style("fill","black")
          //.style("fill", function(d) {
          //    return colourmap[d.c];})

}
        

        draw_scatterplot = function(message) {
        
          
        svg.selectAll(".path1")
             .data(message.d)
             .enter().append("path")
             .attr("class","path1")
             .attr("transform", function(d) { return "translate(" + x(d.x) + "," + y(d.y) + ")"; })
             .attr("d", d3.svg.symbol().type("circle").size(5*5))
             .attr("r", 2)
            .style("fill", function(d) {
              if (colZon===0) {return colourmap[d.c];}
              else {
                return colorScale(d.c);}
            })
            .append("svg:title")
            .text(function(d) {return d.pL})
          
            
        svg.selectAll(".line1")
        .data(message.a)
        .enter()
        .append("line")
        .attr("class","line1")
        .attr("x1", function() {return x(0)})
        .attr("y1", function() {return y(0)})
        .attr("x2",function(d) {return x(d.x)})
        .attr("y2", function(d) {return y(d.y)})
        .attr("stroke-width", 2)
        .attr("stroke","black");
        svg.selectAll(".text1")
        .data(message.a)
        .enter()
        .append("text")
        .attr("class","text1")
        .attr("x", function(d) {return x(d.x)})
        .attr("y", function(d) {return y(d.y)})
        .text(function(d) {return d.n})
        }
        
        draw_cube = function(message) {
           //document.getElementById('d3_output').innerHTML = message.cubeA;

            svg.selectAll(".line2")
            .data(message.cube)
            .enter()
            .append("line")
            .attr("class","line2")
            .attr("x1", function(d) {return x(d.ax)})
            .attr("y1", function(d) {return y(d.ay)})
            .attr("x2",function(d) {return x(d.bx)})
            .attr("y2", function(d) {return y(d.by)})
            .attr("stroke-width", 2)
            .attr("stroke","grey")
            .attr("opacity",0.5);
            }
        
        
            
        
        
        
        
        if (initialised === 0) {
           svg.select(".loading").remove();
           draw_scatterplot(message);
        } else  {
          
          // document.getElementById('d3_output').innerHTML = duration; //"trying to transition";

          svg.selectAll(".path1").remove();
          svg.selectAll(".path2").remove();
          svg.selectAll(".point").remove();
          svg.selectAll(".line1").remove();
          svg.selectAll(".text1").remove();
          svg.selectAll(".line2").remove();
          draw_scatterplot(message);
          if (showMeta == 1) {draw_metadata(message);}
          if (showCube == 1){draw_cube(message);}
          
        }

        initialised = 1;


    });