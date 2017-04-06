({
    startSearching : function(component, event) {
        if (!component || !component.isValid()) {
            return;
        }
        console.log('keyCode');
        console.log(event.getParams().keyCode);
        // if (event.getParams().keyCode === 40) {
        //     this.changeResult(component, event);
        //     return;
        // }

        console.log('startSearching');
        // var projects = component.get('v.projectsAll');
        // console.log('projects');
        // console.dir(projects);
        var textForSearch = component.get('v.textForSearch');
        if (textForSearch) {
            textForSearch = textForSearch.trim().toLowerCase();
        }
        console.log('textForSearch', textForSearch);

        var clientsAll = component.get('v.clientsAll');
        var clientsChoosed = clientsAll.filter(function(client) {
            if (client.Account__r.Name) {
                return client.Account__r.Name.toLowerCase().match(textForSearch);
            }
            else {
                return false;
            }
        });

        component.set('v.clientsChoosed', clientsChoosed);

        this.viewClientsChoosed(component);
    },
    clickClient : function(component, event) {
        if (!component || !component.isValid()) {
            return;
        }
        console.log('clickClient');
        var currentKey = event.currentTarget.dataset.key;
        console.log('currentKey=', currentKey);
        var clientsChoosed = component.get('v.clientsChoosed');
        if (clientsChoosed.hasOwnProperty(currentKey)) {
            var currentClient = clientsChoosed[currentKey];
            console.log('currentClient', currentClient);
            component.set('v.textForSearch', currentClient.Account__r.Name);

            clientsChoosed = [];
            clientsChoosed.push(currentClient);
            console.log(clientsChoosed);
            component.set('v.clientsChoosed', clientsChoosed);
            this.fireClientEvent(component);
        }
        this.hideBlock(component, 'blockResult');

        console.log('finish');
    },
    fireClientEvent : function(component) {
        console.log('fireClientEvent start');
        if (!component || !component.isValid()) {
            return;
        }
        var getClientEvent = component.getEvent('getClient');
        var clientsChoosed = component.get('v.clientsChoosed');
        if (clientsChoosed.hasOwnProperty('0')) {
            getClientEvent.setParams({'selectedClient' : clientsChoosed[0]});
            console.log('getClientEvent.fire()');
            console.log(getClientEvent);
            getClientEvent.fire();
        }
        console.log('fireClientEvent finish');
    },
    viewClientsChoosed : function(component) {
        console.log('viewClientsChoosed');

        var textForSearch = component.get('v.textForSearch');
        var clientsChoosed = component.get('v.clientsChoosed');
        if (textForSearch.length > 0 && clientsChoosed.length > 0) {
            this.showBlock(component, 'blockResult');
        }
        else if(textForSearch.length === 0) {
            console.log('SPARTA!!!!!!!!!!!!!!');
            var projectsAll = component.get('v.projectsAll');
            console.log('projectsAll', projectsAll);

            component.set('v.projectsChoosed', projectsAll);
            this.hideBlock(component, 'blockResult');
        }
        else {
            this.hideBlock(component, 'blockResult');
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