({
    getProject : function(component) {
        if (!component || !component.isValid()) {
            return;
        }
        console.log('getProject');

        var spinner = component.find('loadSpinner');
        if (spinner) {
            $A.util.removeClass(spinner, 'slds-hide');
        }
        // console.log('getProject1');

        var action = component.get("c.getProjects");
        // console.log('getProject2');

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                component.set('v.projectsAll', response.getReturnValue());
                component.set('v.projectsChoosed', response.getReturnValue());
                console.log('getProjects');
                console.dir(response.getReturnValue());
                this.setClientsIntoAttr(component);
                $A.util.addClass(spinner, 'slds-hide');
            }
            else {
                console.log('error getProjects');
            }
        });
        $A.enqueueAction(action);
    },
    // startSearching : function(component, event) {
    //     if (!component || !component.isValid()) {
    //         return;
    //     }
    //     console.log('keyCode');
    //     console.log(event.getParams().keyCode);
    //     if (event.getParams().keyCode === 40) {
    //         this.changeResult(component, event);
    //         return;
    //     }

    //     console.log('startSearching');
    //     var projects = component.get('v.projectsAll');
    //     console.log('projects');
    //     console.dir(projects);
    //     var textForSearch = component.get('v.textForSearch');
    //     if (textForSearch) {
    //         textForSearch = textForSearch.trim().toLowerCase();
    //     }
    //     console.log('textForSearch', textForSearch);

    //     var clientsAll = component.get('v.clientsAll');
    //     var clientsChoosed = clientsAll.filter(function(client) {
    //         if (client.Account__r.Name) {
    //             return client.Account__r.Name.toLowerCase().match(textForSearch);
    //         }
    //         else {
    //             return false;
    //         }
    //     });

    //     component.set('v.clientsChoosed', clientsChoosed);

    //     this.viewClientsChoosed(component);


    // },
    changeResult : function(component, event) {
        console.log('changeResult');

    },
    // viewClientsChoosed : function(component) {
    //     console.log('viewClientsChoosed');

    //     var textForSearch = component.get('v.textForSearch');
    //     var clientsChoosed = component.get('v.clientsChoosed');
    //     if (textForSearch.length > 0 && clientsChoosed.length > 0) {
    //         this.showBlock(component, 'blockResult');
    //     }
    //     else if(textForSearch.length === 0) {
    //         console.log('SPARTA!!!!!!!!!!!!!!');
    //         var projectsAll = component.get('v.projectsAll');
    //         console.log('projectsAll', projectsAll);

    //         component.set('v.projectsChoosed', projectsAll);
    //         this.hideBlock(component, 'blockResult');
    //     }
    //     else {
    //         this.hideBlock(component, 'blockResult');
    //     }
    // },
    getClientEvent : function(component, event) {
        console.log('getClientEvent');
        var selectedClient = event.getParam("selectedClient");
        component.set("v.selectedClient", selectedClient);
        console.log('selectedClient', selectedClient);
    },
    setClientsIntoAttr : function(component) {
        if (!component || !component.isValid()) {
            return;
        }
        console.log('getClients');

        projects = component.get('v.projectsAll');
        console.log('projects');
        console.dir(projects);

        var clients = [],
            isRepeatedClient;
        console.log('before forEach');

        projects.forEach(function(project) {
            console.log('forEach');
            isRepeatedClient = clients.some(function(client) {
                console.log('client.Id', client.Id);
                console.log('project.Customer__c', project.Customer__c);
                return client.Id === project.Customer__c;
            });
            if (!isRepeatedClient) {
                clients.push(project.Customer__r);
            }
        });

        console.log('clients');
        console.dir(clients);
        component.set('v.clientsAll', clients);
    },
    // clickClient : function(component, event) {
    //     if (!component || !component.isValid()) {
    //         return;
    //     }
    //     console.log('clickClient');
    //     var currentKey = event.currentTarget.dataset.key;
    //     console.log('currentKey=', currentKey);
    //     var clientsChoosed = component.get('v.clientsChoosed');
    //     if (clientsChoosed.hasOwnProperty(currentKey)) {
    //         var currentClient = clientsChoosed[currentKey];
    //         console.log('currentClient', currentClient);
    //         component.set('v.textForSearch', currentClient.Account__r.Name);

    //         clientsChoosed = [];
    //         clientsChoosed.push(currentClient);
    //         console.log(clientsChoosed);
    //         component.set('v.clientsChoosed', clientsChoosed);
    //         this.filterProjectList(component);
    //     }
    //     this.hideBlock(component, 'blockResult');

    //     console.log('finish');
    // },
    filterProjectList : function (component) {
        if (!component || !component.isValid()) {
            return;
        }
        console.log('filterProjectList');

        var clientsChoosed = component.get('v.clientsChoosed');
        console.log('clientsChoosed');
        console.dir(clientsChoosed);
        var projectsAll = component.get('v.projectsAll');
        if (clientsChoosed.hasOwnProperty('0')) {
            var projectsChoosed = projectsAll.filter(function(project) {
                return project.Customer__c === clientsChoosed[0].Id
            });
            component.set('v.projectsChoosed', projectsChoosed);
        }
    },
    hideBlock : function (component, nameTag) {
        if (component && component.isValid()) {
            var block = component.find(nameTag);
            if (block) {
                $A.util.addClass(block, "slds-hide");
            }
        }
    },
    showBlock : function (component, nameTag) {
        if (component && component.isValid()) {
            var block = component.find(nameTag);
            if (block) {
                $A.util.removeClass(block, "slds-hide");
            }
        }
    },

})