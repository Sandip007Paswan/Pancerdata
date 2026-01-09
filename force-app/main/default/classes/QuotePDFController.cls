public class QuotePDFController 
{
	@AuraEnabled
    public static ContentVersion getQuotePDFId(Id parentId)
    {
        ContentVersion cv = null;
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId];        
        if (links != NULL && links.size() > 0)
        {
            Set<Id> contentDocumentIds = new Set<Id>();
            List<ContentVersion> versions = [SELECT ContentDocumentId, ContentSize FROM ContentVersion ORDER BY CreatedDate DESC LIMIT 1];
            if (versions != NULL && versions.size() > 0)
            {
                cv = versions.get(0); 
            }
        }
        return cv;
    }
}