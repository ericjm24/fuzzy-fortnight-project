let cy = cytoscape({
    container: document.getElementById("cy")
});

/*let nod = cy.add(testNodes);
let ed = cy.add(testEdges);*/

let butt = document.getElementById("doit");
var summaryX = [];
var summaryY = [];
var summaryC = [];
let centerPos = {x:300, y:300}

let buildGraph = function(data){
    console.log(data);
    cy.remove(cy.nodes());
    let mainNode = {group:'nodes', data:{id:data.userID}, position:centerPos, color:data.color};
    cy.add([mainNode]);
    let sideNodes = data.connectionList.map(d=>{
        let out = {
            group:'nodes',
            data:{id:d.userID},
            position:{x:500*Math.random(),y:500*Math.random()}
        };
        return out
    });
    let edges = data.connectionList.map(d=>{
        let out = {
            group : 'edges',
            data: {source:data.userID, target:d.userID},
            width:d.weight
        };
        return out
    });
    cy.add(sideNodes);
    cy.add(edges);

    let plotdata = {
        x:data.connectionList.map(d=>`TID ${d.userID}`),
        y:data.connectionList.map(d=>d.weight),
        marker:{
            color:data.connectionList.map(d=>d.color)
        },
        type:'bar'
    };

    let layout = {
        title:{text:`Weight of Twitter Connections for ID ${data.userID}`,
            size:24},
        yaxis:{title:{text:"Weight"}}

    }
    Plotly.newPlot('barplot', [plotdata], layout);
    let bInArray = false
    for (let x in summaryX){
        if (x.userID == data.userID){bInArray=true}
    };
    if (bInArray == false){
        summaryX.push(data.userID);
        weight = 0;
        total = 0;
        for (let c of data.connectionList){
            total += c.weight
            if (c.color == "red"){weight += c.weight} else if (c.color == "blue"){weight += -c.weight};
        };
        if (total==0){total=1};
        summaryY.push(weight/total);
        summaryC.push(data.color)
        let summaryData = {
            x:summaryX.map(x=>`ID ${x}`),
            y:summaryY,
            marker:{color:summaryC},
            type:'bar'
        }
        let layour = {
            title:{
                text:"Summary of congress",
                size:24
            }
        }
        Plotly.newPlot('totalplot', [summaryData], layour)
    }
}

let lili = document.getElementsByClassName("congressmember")

for (let n of lili){
    n.onclick = function(){
        d3.json("user/" + n.id).then(data=>buildGraph(data))
    };
};
