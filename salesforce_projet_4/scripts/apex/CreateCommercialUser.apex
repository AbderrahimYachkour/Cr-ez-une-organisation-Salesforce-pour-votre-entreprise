// Crée un utilisateur de test avec le profil Commercial pour tester l'affichage conditionnel du LWC.
// L'utilisateur est créé en français (langue + locale) et l'email de bienvenue est désactivé.

Profile commercialProfile = [SELECT Id FROM Profile WHERE Name = 'Commercial' LIMIT 1];

User commercialUser = new User(
    FirstName = 'Test',
    LastName = 'Commercial',
    Email = 'abderrahim.elmaachi@gmail.com',
    Username = 'commercial.test.20260511@vitesse.com',
    Alias = 'tCom',
    ProfileId = commercialProfile.Id,
    LanguageLocaleKey = 'fr',
    LocaleSidKey = 'fr_FR',
    TimeZoneSidKey = 'Europe/Paris',
    EmailEncodingKey = 'UTF-8'
);

Database.DMLOptions dmlOpts = new Database.DMLOptions();
dmlOpts.EmailHeader.triggerUserEmail = false;
Database.SaveResult result = Database.insert(commercialUser, dmlOpts);

if (result.isSuccess()) {
    System.debug('=== Utilisateur Commercial créé avec succès ===');
    System.debug('Id        : ' + commercialUser.Id);
    System.debug('Username  : ' + commercialUser.Username);
    System.debug('Langue    : ' + commercialUser.LanguageLocaleKey);
    System.debug('Pour te connecter en tant que cet utilisateur :');
    System.debug('  Setup -> Users -> Test Commercial -> clique sur "Login"');
} else {
    System.debug('=== Erreur lors de la création ===');
    for (Database.Error err : result.getErrors()) {
        System.debug(err.getStatusCode() + ' : ' + err.getMessage());
    }
}
