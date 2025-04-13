function kmgReverse(num){
    let letter=num.slice(-1);//gets last
    let formatted=num.slice(0, -1);//all but last
    let kilo=1000;

    if ('K'==letter){
        return formatted*kilo;
    }
    else if('M'==letter){
        return formatted*kilo*kilo;
    }
    else if('G'==letter){
        return formatted * kilo*kilo*kilo;
    }
    else{
        return num;
    }
    // if(num < kilo){
    //        formatted=Math.round(num * 100) / 100
    //     return formatted+"";
    // }
    // else if(num >=kilo && num<(kilo*kilo)){
    //     // formatted=num%(1024)
    //     formatted=Math.round(num/(kilo) * 100) / 100
    //     return formatted+"K";
    // }
    // else if(num >=(kilo*kilo) && num < (kilo*kilo*kilo)){
    //     formatted=Math.round(num/(kilo*kilo) * 100) / 100
        

    //     return formatted+'M';
    // }
    // else if(num >=kilo*kilo*kilo){
    //     formatted=Math.round(num/(kilo*kilo*kilo) * 100) / 100
    //     return formatted+'G';
    // }
}
function parseKMG(str){
    const regex=/[A-Z]/i;
    if(regex.test(str)){
        return([str.slice(0, -1)*1,str.slice(-1).toUpperCase()])
    }
    return([str*1]);
}
function filterMax(){
    let val=$('#filter').val();
    if(val.length === 0){
        $('.gr_container').show();
        return;
    }
    let [num,metric]=parseKMG(val);
    $('.gr_container').hide();
    $('.max').each(function(){
        let txt=$(this).text();
        if(metric){
            if(txt.includes(metric)){
                //compare
                if(parseKMG(txt)[0]>num){
                    $(this.closest('.gr_container')).show();
                }
            }
        }else{
            //compare
            if(parseKMG(txt)[0]>num){
                $(this.closest('.gr_container')).show();
            }
        }
      })
}