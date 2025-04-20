function resizeIframe(obj) {    
    // console.log(obj);                                                                                                                                                                 
// obj.style.height = 400 + 'px';                                                                                                                                                                     
obj.style.height = obj.contentWindow.document.body.scrollHeight+200 + 'px';                                                                                                                  
// obj.style.width = obj.contentWindow.document.body.scrollWidth + 'px';  
// console.log(obj.contentWindow.document.body.scrollHeight);                                                                                                  
 }
 function addToDash(btn){
    // console.log(btn);
    let port_id=btn.getAttribute("port_id");
    let dashboard_id=btn.closest('td').querySelector('[name=dashboard_id]').value;
    if(!dashboard_id || '0' == dashboard_id || 0===dashboard_id){
        console.log("no dashboard");
        return;
    }
    //todo: post
    console.log(port_id,dashboard_id);
    perlPost(port_id,dashboard_id);
}
function perlPost(port_id,dashboard_id){
    fetch("router.cgi", {
  method: "POST",
  body: `port_id=${port_id};dashboard_id=${dashboard_id};add_to_dash=true;`,
  headers: {
    "Content-type": "application/x-www-form-urlencoded; charset=UTF-8"
  }
})
    .then((response)=>{
      if(200==response.status){
        printMsg("<h4>Add to dashboard success</h4>");
      }
    })
}
function printMsg(msg){
  if(!msg || "" == msg){
    msg="<h4>Loading graphs... please wait</h4>";
  }
  document.getElementById("infobox").innerHTML=msg;
  return 1;
}
function selRow(input){
  input.closest('tr').querySelector('[name=sel]').click();
}
function sure(e){
  if (confirm("sure to delete?")) {
  return 1;
  }else{
    e.preventDefault();
    return 0;
  }
}