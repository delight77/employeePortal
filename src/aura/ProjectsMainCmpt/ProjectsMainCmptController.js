({
    doInit : function(component, event, helper) {
        helper.getProject(component);
    },
    startSearching : function(component, event, helper) {
        helper.startSearching(component, event);
    },
    clickClient : function(component, event, helper) {
        helper.clickClient(component, event);
    },
    getEvent : function(component, event, helper) {
        console.log('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
        console.log('getClientEvent ssssskjgffrugfeuirfgskjhgfkjygfshdjls');
        helper.getClientEvent(component, event);
    }
})