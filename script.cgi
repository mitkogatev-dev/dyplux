#!/usr/bin/perl -w

package js;
##script.cgi
#perl script to return required javascript
#
use strict;
use CGI qw(-utf8);
use CGI::Carp qw(fatalsToBrowser);
use JSON;
use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
my $clip=$ENV{REMOTE_ADDR};
my $ref=$ENV{HTTP_REFERER};
my $cgi = new CGI;
$cgi->charset('utf-8');
$CGI::LIST_CONTEXT_WARN = 0 ;
my @params=$cgi->param();
my $request_method=$cgi->request_method();

my %input;
for my $key ( $cgi->param() ) {
 $input{$key} = $cgi->param($key);
}

########################################
#magic
print $cgi->header("text/javascript;charset=UTF-8");
#
#
my $output="";
### LOCK prevent direct access
# if ($ref !~ /router.cgi/gi){ print "bye"; exit 0;}
#
require "$dir/config.pl";
require "$dir/influx.pl";
require "$dir/service.pl";
require "$dir/query.pl";
my $cfg=Cfg::get_config();
my $graphjs="";

$graphjs=q(
    function kmgFormat(num){
        let formatted='';
        let kilo=1000;
        if(num < kilo){
               formatted=Math.round(num * 100) / 100
            return formatted+"";
        }
        else if(num >=kilo && num<(kilo*kilo)){
            // formatted=num%(1024)
            formatted=Math.round(num/(kilo) * 100) / 100
            return formatted+"K";
        }
        else if(num >=(kilo*kilo) && num < (kilo*kilo*kilo)){
            formatted=Math.round(num/(kilo*kilo) * 100) / 100
            
    
            return formatted+'M';
        }
        else if(num >=kilo*kilo*kilo){
            formatted=Math.round(num/(kilo*kilo*kilo) * 100) / 100
            return formatted+'G';
        }
    }
    function checkElem(id) {
        let sideBtns=`<form action="" method="post"><input type="hidden" name="port_id" value="${id}"/><ul>
                        <li><input type="submit" value="threshold" name="port_threshold">
                        </li>
                        <li>dashboard</li>
                        <li>disable</li>
                        
                      </ul></form>
                      <form action="" method="post" target="_blank">
                      <input type="hidden" name="port_id" value="${id}"/>
                      <ul><li>
                      <input type="submit" value="openPOST" name="single_graph"/>
                      </li></ul>
                      </form>
                      `;
        if (document.getElementById(id) == null) {
            let grDiv=$('<div>').attr('id', id).addClass('graph');
            let botDiv=$('<div>').attr('id', 'foo'+id).addClass('grfooter');
            let menuDiv=$('<div>').attr('id', 'side'+id).addClass('grside').append(sideBtns);
            let container=$('<div>').addClass('gr_container');
            container.append(grDiv);
            container.append(menuDiv);
            container.append(botDiv);
            $('#div_g').append(container);
        }
    }
    function parse(response,arg) {
        console.log(response);
        const data = [];
        const series = response.results[0].series;
        const lbls = series[0].columns;//labels 3 columns
        const tag = "port_id"; //todo get tag from query
        for (let j in series) {
            let idx = "";
            let graphData = [];
            let minIn=9999999999;
            let maxIn=-9999999999;
            let minOut=9999999999;                                                                                                                                                            
            let maxOut=-9999999999;
    
            series[j].values.map((elem, i) => { 
                let formattedPoint = [];
                formattedPoint.push(new Date(Date.parse(elem[0])));//first elem is the time always
                formattedPoint.push(elem[1]);
                formattedPoint.push(elem[2]);
                //min max
                 if(elem[1]<minIn){minIn=elem[1]};
                 if(elem[1]>maxIn){maxIn=elem[1]};
                 if(elem[2]<minOut){minOut=elem[2]};                                                                                                                                                    
                 if(elem[2]>maxOut){maxOut=elem[2]};
    
                graphData.push(formattedPoint);
            });
    
            idx = series[j].tags[tag];
            let minMax={'minIn':minIn,'maxIn':maxIn,'minOut':minOut,'maxOut':maxOut};
            data.push([idx, graphData,minMax]);
        }
        return data;
    }
);
############## graph.js with js fetch ########
if($cfg->{influx_query_method} && "js" eq $cfg->{influx_query_method}){
# my $q=Influx_curl::query_builder("device",$input{device_id});
my $q=Influx_curl::query_builder(\%input);
 $graphjs.=qq( 
    function buildQuery() {
    let host = "$cfg->{influx_url}";
    const db='$cfg->{influx_bucket}';
    let query="$q";
 );
 $graphjs.=q(
        return (encodeURI(`${host}query?db=${db}&q=${query}`));
    }
 );
#  my $q=Influx_curl::query_builder();
 $graphjs.=qq(
    const fetchData = () => {
        const query = buildQuery();
        return fetch(query, {
            credentials: "include", headers: {
                Authorization: "Token $cfg->{influx_token}",
            },
        })
            .then(response => {
                if (response.status !== 200) {
                    console.log(response);
                }
                return response;
            })
            .then(response => response.json())
            .then(parsedResponse => {
                return parse(parsedResponse);//todo
            })
            .catch(error => console.log(error));
    }
 );
 $graphjs.=q(
    function drawGraph(args){
        //let graphType=arr[0];
        //let ids=arr[1];//
        //let ports=arr[2];//
        //let argsArr=[graphType,ids]; //0-graphtype(device,port,dashboard);,
        let ports = args[0];
        let graphsArr = [];
        $('#div_g').empty();
        console.log(ports);
    
        Promise.resolve(fetchData())
            .then(data => {
                console.log(data);
        for (let i in data) {
            let idx = data[i][0];
            let minMax=data[i][2];
            let currPort=ports.find(port => port.port_id == idx);
                if(!currPort) continue;
            checkElem(idx);//create graph container if none
            $('#foo'+idx).html(`minIn: <b>${kmgFormat(minMax.minIn)} </b> maxIn: <b><span class='max'>${kmgFormat(minMax.maxIn)}</span></b> minOut: <b>${kmgFormat(minMax.minOut)}</b> maxOut: <b><span class='max'>${kmgFormat(minMax.maxOut)}</span></b>`);
            let title=currPort.device_name+" - "+currPort.ifname+" -- "+currPort.port_name;
    graphsArr.push(
        new Dygraph(
            document.getElementById(idx),
            data[i][1],
            {
            labelsKMB: true, //using dygraph-combined.js with replaced string "B" to "G"
              legend: 'follow',
            showRangeSelector:true,
            interactionModel: {},
              drawPoints: false,
              stepPlot: true,
              ylabel: 'bits/second',
              fillGraph: true,
              highlightCircleSize:5,
              title: title,
              titleHeight:20,
              height:300,
              labels: ['Time', 'IN', 'OUT'],
              underlayCallback: function(canvas, area, g) {
                function highlightYaxesWithColour(y_start, y_end, color) {
                  let canvas_bottom = g.toDomYCoord(y_start);
                  let canvas_top = g.toDomYCoord(y_end);
                  let canvas_height = canvas_top - canvas_bottom;
                  canvas.fillStyle = color;
                  canvas.fillRect(area.x, canvas_bottom, area.w, canvas_height);
                }
                      
                let color1 = "rgba(255, 255, 0, 1.0)";//>=100M
                let color2 = "rgba(255, 150, 0, 1.0)";//>1G
                let color3 = "rgba(255, 0, 0, 1.0)"; //<=9Mbps
                
                highlightYaxesWithColour(100000000,100000000*10,color1);
                highlightYaxesWithColour(100000000*10,100000000*100*100,color2);
                highlightYaxesWithColour(0,9000000,color3);
              }
              ///////
            })
    
        )}
        resizeIframe(parent.document.getElementById('frame'));
    
    });
    }
 );
}else{ #curl
    $graphjs.=q(
    function drawGraph(arr){
    // let deviceId=arr[0];
    //let graphType=arr[0];
    //let ids=arr[1];//
    let ports=arr[0];//
    let jsonData=arr[1];//

    //let argsArr=[graphType,ids]; //0-graphtype(device,port,dashboard);,
    let graphsArr = [];
    $('#div_g').empty();

    let data=parse(jsonData);
            console.log(data);
    for (let i in data) {
        let idx = data[i][0];
        let minMax=data[i][2];
        // console.log(idx);
        let currPort=ports.find(port => port.port_id == idx);
            if(!currPort) continue;
        checkElem(idx);//create graph container if none
        $('#foo'+idx).html(`minIn: <b>${kmgFormat(minMax.minIn)} </b> maxIn: <b><span class='max'>${kmgFormat(minMax.maxIn)}</span></b> minOut: <b>${kmgFormat(minMax.minOut)}</b> maxOut: <b><span class='max'>${kmgFormat(minMax.maxOut)}</span></b>`);
        let title=currPort.device_name+" - "+currPort.ifname+" -- "+currPort.port_name;
    graphsArr.push(
    new Dygraph(
        document.getElementById(idx),
        data[i][1],
        {
        
        labelsKMB: true, //using dygraph-combined.js with replaced string "B" to "G"
        // labelsKMG2: true,
          legend: 'follow',
        showRangeSelector:true,
        interactionModel: {},
          drawPoints: false,
          stepPlot: true,
          ylabel: 'bits/second',
          fillGraph: true,
          highlightCircleSize:5,
          title: title,
          titleHeight:20,
          height:300,
          labels: ['Time', 'IN', 'OUT'],
          ///////
          underlayCallback: function(canvas, area, g) {
            function highlightYaxesWithColour(y_start, y_end, color) {
              let canvas_bottom = g.toDomYCoord(y_start);
              let canvas_top = g.toDomYCoord(y_end);
              let canvas_height = canvas_top - canvas_bottom;

              canvas.fillStyle = color;
              canvas.fillRect(area.x, canvas_bottom, area.w, canvas_height);
            }
                  
       		let color1 = "rgba(255, 255, 0, 1.0)";//>=100M
            let color2 = "rgba(255, 150, 0, 1.0)";//>1G
			let color3 = "rgba(255, 0, 0, 1.0)"; //<=9Mbps
            
            highlightYaxesWithColour(100000000,100000000*10,color1);
            highlightYaxesWithColour(100000000*10,100000000*100*100,color2);
            highlightYaxesWithColour(0,9000000,color3);
          }
          ///////
        })

    )}
}
    );
}

$output.=$graphjs;
######## function using perl vars
$output.=qq(
    function varpl(){
        console.log("your ip taken from \$cgi is $clip");
        console.log("hashes = \$input{test}  \$input{varname} is working if passed by script src");
        console.log("hashes = $cfg->{influx_url} \$cfg->{vars} are also available");
    }
);

print $output;
###debug
print "/**".Dumper($cgi)."*/";
# print "/**".Dumper(%ENV)."*/";
# print "/**".Dumper($cfg)."*/";
