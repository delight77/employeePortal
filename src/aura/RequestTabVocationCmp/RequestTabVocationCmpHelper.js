({
	clearForm : function(component) {
		component.find('dateStartVocation').set("v.value", "");
        component.find('dateEndVocation').set("v.value", "");
        component.find('paid').set("v.value", "false");
        component.find('detail').set("v.value", "");
        $('#main-page').show();
        $('#vacation-container').hide();
        
	},
	getObjectInfo : function(component) {
		var actionSetObjectInfo = component.get("c.getCurrentContactInfo");
        actionSetObjectInfo.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var dateStartFormat = new Date(response.getReturnValue()[0]);
                var dateEndFormat = new Date(response.getReturnValue()[1]);
                var dateStartFormatString = dateStartFormat.toLocaleDateString("en-US", 
                {
                    year: "numeric", month: "short",
                    day: "numeric"
                });
                var dateEndFormatString = dateEndFormat.toLocaleDateString("en-US", 
                {
                    year: "numeric", month: "short",
                    day: "numeric"
                });
                component.set("v.yearStart", dateStartFormatString);
                component.set("v.yearEnd", dateEndFormatString);
                component.set("v.daysAccruedYid", response.getReturnValue()[2]);
                component.set("v.spentYid", response.getReturnValue()[3]);
                component.set("v.remainingYid", response.getReturnValue()[4]);
            }
        });
        $A.enqueueAction(actionSetObjectInfo);
	},
	getUserProjects : function(component) {
		var allUserProjects = component.get("c.getProjectsForUser");
        
        allUserProjects.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var ite = 0;
                for (var i = 0; i < response.getReturnValue().length; i++) {   
                    $A.createComponent(                      
                        "c:CustomLookupForReplacementCmp",
                        {
                            "LabelForSelect": "Project: " + response.getReturnValue()[i],
                            "outputId": response.getReturnValue()[i],
                            "outputClass": "outputUserName"
                        },
                        function(newElement, status, errorMessage){
                            if (status === "SUCCESS") {
                                var body = component.get("v.body");
                                body.push(newElement);
                                component.set("v.body", body); 
                            }
                            
                        }
                    );     
                }   
            }
        });
        $A.enqueueAction(allUserProjects);
	},

})