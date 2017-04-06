({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 

        var action = component.get("c.fetchUsers");
        // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.listOfSearchRecords", null);
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.
                if(storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", 'Search Result...');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", response.getReturnValue());
            }
 
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    
    },
})