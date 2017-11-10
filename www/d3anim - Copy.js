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
    density = 1;
    
    
    // colorbrewer scales @ https://bl.ocks.org/mbostock/5577023
    // and http://colorbrewer2.org/
    
Shiny.addCustomMessageHandler("parameters", function(message) {aps = Number(message[0]), fps = Number(message[1])});

var duration = 1000 / 1;

var svg = d3.select("#d3_output_2")
    .append("svg")
    .attr("width", w)
    .attr("height", h);

var x = d3.scale.linear().domain([-1, 1]).range([left_pad, w - pad]),
    y = d3.scale.linear().domain([-1, 1]).range([pad, h - pad * 2]);

var xAxis = d3.svg.axis().scale(x).orient("bottom")
    .ticks(10);

var yAxis = d3.svg.axis().scale(y).orient("left")
    .ticks(10);

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

Shiny.addCustomMessageHandler("density",
  function(message) {
    density = Number(message[0]);
    // document.getElementById('info_2').innerHTML = density;
  }
)

Shiny.addCustomMessageHandler("debug",
  function (message){
    document.getElementById('d3_output').innerHTML = message;
  })

Shiny.addCustomMessageHandler("newcolours",
function(message) {
  
  
  
  
  l = message.length
  palette = d3.scaleOrdinal(d3.schemeDark2);
  
  for (i = 0; i < l; i++) {
    colourmap[message[i]] = palette(i); // for discrete palettes
    // colourmap[message[i]] = palette((i+1)/(l+1)); // for continuous palettes
    }
}
)

Shiny.addCustomMessageHandler("contour",
  function(message) {
    
    document.getElementById('d3_output').innerHTML = message
    
    svg.insert("g", "g").append("svg")
    .attr("width", w)
    .attr("height", h)
    .selectAll("path")
      .data(message.map(function(d) {
        return d3.range(message.x.length).map(function(i) {
          return {x: d.x[i], y: d.y[i]};
        });
      }))
    .enter().append("svg:path")
      .attr("d", line)
      .on("mouseover", function(d, i) {
        d3.select(this).style("stroke", "yellow");
      })
      .on("mouseout", function(d, i) {
        d3.select(this).style("stroke", "darkgreen");
      })
      .style("fill", "none")
      .style("stroke", "darkgreen")
      .style("stroke-width", 0)
      .transition()
      .style("stroke-width", 2);
  }
)

Shiny.addCustomMessageHandler("data",
    function(message) {
        
        //Shiny.addCustomMessageHandler("countour")
        
        // document.getElementById('d3_output').innerHTML = message;
        
        svg.select(".loading").remove();
        
        draw_contourplot = function(message) {
          svg.insert("g", "g")
      .attr("fill", "none")
      .attr("stroke", "blue")
      .attr("stroke-linejoin", "round")
      .selectAll("path")
      .data(d3.contourDensity()
        .x(function(d) { return x(d[0]); })
        .y(function(d) { return y(d[1]); })
        .size([w, h])
        .bandwidth(40)
      (message))
    .enter().append("path")
      .attr("d", d3.geoPath())
      .transition();
        }

        draw_scatterplot = function(message) {
          svg.selectAll("circle")
            .data(message)
            .enter()
            .append("circle")
            .attr("class", "circle")
            .attr("cx", function(d) {
                return x(d[1]);
            })
            .attr("cy", function(d) {
                return y(d[0]);
            })
            .attr("r", 2)
            .attr("fill", function(d) {
              return colourmap[d[2]];
            })
            
        }
        
        draw_legend = function(message) {
          var legend = svg.selectAll(".legend")
      .data(message)
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });
      
       // draw legend colored rectangles
  legend.append("rect")
      .attr("x", w - 18)
      .attr("width", 18)
      .attr("height", 18)
      .style("fill", function(d) {
        return colourmap[d[2]];
      });
      
      
      legend.append("text")
      .attr("x", w - 24)
      .attr("y", 9)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function(d) { return d[2];});
      
        }
        
        
        if (initialised === 0) {
           draw_scatterplot(message);
           draw_legend(message);
           //draw_contourplot(message);
        } else  {
          
          // document.getElementById('d3_output').innerHTML = duration; //"trying to transition";
          svg.selectAll(".legend").remove();
          svg.selectAll(".path").remove();
          svg.selectAll("circle").remove();
          draw_scatterplot(message);
          draw_legend(message);
          
          if (density == 1) {
            draw_contourplot(message);  
          } else {
            svg.selectAll("path").remove();
          }
        }

        initialised = 1;


    });