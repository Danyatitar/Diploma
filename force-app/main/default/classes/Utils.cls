public without sharing class Utils {
    static String namespacePrefix;

    @AuraEnabled(cacheable=true)
    public static string getNamespacePrefix(){
        String namespace;

        if(namespacePrefix == null){
            if(Utils.class.getName().contains('.')){
                namespacePrefix = Utils.class.getName().substringBefore('.');
            }
            if(String.isNotBlank(namespace)){
                namespacePrefix += '__';
            }else{
                namespacePrefix = '';
            }
        }

        return namespacePrefix;
    }
}