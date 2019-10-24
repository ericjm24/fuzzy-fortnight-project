let cy = cytoscape({
    container: document.getElementById("cy")
});

let testNodes = [
    {group:'nodes', data:{id:'n1'}, position:{x:500*Math.random(),y:500*Math.random()}},
    {group:'nodes', data:{id:'n2'}, position:{x:500*Math.random(),y:500*Math.random()}},
    {group:'nodes', data:{id:'n3'}, position:{x:500*Math.random(),y:500*Math.random()}},
    {group:'nodes', data:{id:'n4'}, position:{x:500*Math.random(),y:500*Math.random()}},
    {group:'nodes', data:{id:'n5'}, position:{x:500*Math.random(),y:500*Math.random()}},
];

let testEdges = [
    {group:'edges', data:{id:'e01', source:'n1', target:'n2'}},
    {group:'edges', data:{id:'e02', source:'n1', target:'n3'}},
    {group:'edges', data:{id:'e03', source:'n1', target:'n4'}},
    {group:'edges', data:{id:'e04', source:'n1', target:'n5'}},
    {group:'edges', data:{id:'e05', source:'n2', target:'n3'}},
    {group:'edges', data:{id:'e06', source:'n2', target:'n4'}},
    {group:'edges', data:{id:'e07', source:'n2', target:'n5'}},
    {group:'edges', data:{id:'e08', source:'n3', target:'n3'}},
    {group:'edges', data:{id:'e09', source:'n3', target:'n5'}},
    {group:'edges', data:{id:'e10', source:'n4', target:'n5'}},
];

/*let nod = cy.add(testNodes);
let ed = cy.add(testEdges);*/

let butt = document.getElementById("doit");

let centerPos = {x:300, y:300}

let buildGraph = function(data){
    console.log(data);
    cy.remove(cy.nodes());
    let mainNode = {group:'nodes', data:{id:data.userID}, position:centerPos};
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
}

butt.onclick = function(){
    d3.json("user/75").then(data=>buildGraph(data))
};
