({
    render : function(component, helper) {
        var ret = this.superRender();
        return ret;
    },
    rerender : function(component, helper){
        this.superRerender();
    },
    afterRender: function (component, helper) {
        this.superAfterRender();
    }
})