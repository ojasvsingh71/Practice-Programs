const obj={
    id:42,
    regular: function(){
        setTimeout(function(){
            console.log('regular this :',this);
        },100)
    },
    arrow: function(){
        setTimeout(()=>{
            console.log('arrow this : ',this);
        },100);
    }
}

obj.regular();
obj.arrow()