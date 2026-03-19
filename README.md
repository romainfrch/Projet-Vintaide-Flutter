# Vintaide 

**Romain FRANCHI**

Application mobile de vente de vêtements développée avec Flutter, dans le cadre du TP2 MIAGE – IA2.

---

## 👤 Comptes utilisateurs de test

| Login | Mot de passe |
|-------|-------------|
| user1 | admin       |
| user2 | mdp         |

---

## 🚀 Lancement de l'application

L'application est configurée pour tourner sur **Chrome** (Flutter Web).

### Prérequis

- Flutter **3.41.1** (channel stable)
- Dart **3.11.0**
- Un navigateur Chrome installé

### Installation & démarrage

```bash
# Cloner le repository
git clone https://github.com/romainfrch/Projet-Vintaide-Flutter/
cd vintaide

# Installer les dépendances
flutter pub get

# Lancer sur Chrome
flutter run -d chrome
```

---

## ✅ Fonctionnalités réalisées

### US#1 – Interface de login 
- Page de connexion avec champs Login et Password (obfusqué)
- Vérification des identifiants en base Firestore (collection `users`)
- Redirection vers la liste des vêtements si connexion OK
- Application reste fonctionnelle si les champs sont vides ou si l'utilisateur n'existe pas

### US#2 – Liste des vêtements 
- Affichage de tous les vêtements récupérés en temps réel depuis Firestore (collection `vetements`)
- Chaque article affiche : image, titre, catégorie, taille, prix
- Navigation via `BottomNavigationBar` (Acheter / Panier / Profil)
- Clic sur un article → accès au détail (US#3)

### US#3 – Détail d'un vêtement 
- Affichage complet : image, titre, catégorie, taille, marque, prix
- Bouton **Retour** vers la liste
- Bouton **Ajouter au panier** (ajout dans `carts/{login}/items`)

### US#4 – Panier 
- Liste des vêtements du panier de l'utilisateur connecté, récupérée en temps réel depuis Firestore
- Stocké dans la collection `carts/{login}/items` → persistant entre les sessions
- Affichage : image, titre, catégorie, taille, prix, quantité
- Total général calculé dynamiquement (prix × quantité)
- Suppression d'un article via la croix → total mis à jour en temps réel

### US#5 – Profil utilisateur 
- Affichage et modification des données récupérées depuis `users/{login}` :
  login (readonly), password (obfusqué), anniversaire (date picker), adresse, code postal (clavier numérique), ville
- Bouton **Valider** pour sauvegarder en base Firestore
- Bouton **Ajouter un nouveau vêtement** → redirige vers le formulaire US#6
- Bouton **Se déconnecter** → efface la session et retourne au login

### US#6 – Ajout d'un vêtement avec détection IA 
- Formulaire d'ajout accessible depuis le profil
- Champs : image, titre, catégorie (détectée automatiquement), taille, marque, prix
- Image compressée en JPEG (max 512px, qualité 75%) avant stockage en base64 dans Firestore
- **Catégorie détectée automatiquement** par analyse visuelle via TensorFlow.js / MobileNet
- Fallback sur règles textuelles (titre + marque + nom de fichier) si l'image n'est pas reconnue
- Sauvegarde dans la collection `vetements`

---

## 🤖 Fonctionnalité IA – Détection de catégorie par vision

La catégorie est détectée automatiquement par **analyse visuelle de l'image** via un modèle de deep learning, sans API externe, sans compte tiers, entièrement dans le navigateur.

### Approche technique

| Composant      | Détail                                              |
|----------------|-----------------------------------------------------|
| Modèle         | MobileNet v2 (TensorFlow.js)                        |
| Exécution      | 100% navigateur (WebGL), aucun serveur              |
| Chargement     | ~4 Mo au premier lancement, mis en cache ensuite    |
| Préchargement  | Silencieux dès l'ouverture de la page d'ajout       |

### Fonctionnement

1. L'utilisateur uploade une image
2. L'image est injectée dans un élément `<img>` temporaire du DOM (224×224px)
3. MobileNet analyse l'image et retourne les 3 labels ImageNet les plus probables
4. Un mapping traduit ces labels vers les catégories Vintaide
5. Si aucun label ne correspond → fallback sur règles textuelles (titre + marque + nom de fichier)

### Mapping ImageNet → catégories Vintaide

| Catégorie     | Exemples de labels détectés                                         |
|---------------|---------------------------------------------------------------------|
| Haut          | jersey, sweatshirt, hoodie, coat, jacket, blazer, dress, kimono…   |
| Pantalon      | jeans, denim, trousers, leggings, sweatpants, cargo…               |
| Short         | shorts, swim brief, swimming trunks…                                |
| Chaussures    | sneaker, boot, sandal, loafer, running shoe, oxford…               |
| Accessoires   | cap, hat, scarf, handbag, backpack, watch, sunglasses…             |
| Autre         | *(fallback si aucun label reconnu)*                                 |

### Exemples d'images de test recommandées

| Image                          | Catégorie attendue |
|--------------------------------|--------------------|
| Photo d'un jean Levi's         | Pantalon           |
| Photo d'un hoodie Nike         | Haut               |
| Photo de baskets Air Max       | Chaussures         |
| Photo d'un short de bain       | Short              |
| Photo d'une casquette snapback | Accessoires        |

> 💡 Pour de meilleurs résultats : photo du vêtement seul, sur fond neutre, bien éclairée.

---

## 🗄️ Structure Firestore

```
firestore/
├── users/
│   ├── user1/          → address, birthday, city, password, postalCode
│   └── user2/          → address, birthday, city, password, postalCode
│
├── carts/
│   └── {login}/
│       └── items/      → sous-collection du panier
│           └── {itemId} → title, categorie, size, price, quantity,
│                          imageBase64, imageUrl
│
└── vetements/
    └── {vetementId}
        → title, categorie, size, brand, price,
          imageBase64, createdBy, createdAt
```

**Exemple de document `vetements` :**

| Champ | Exemple |
|-------|---------|
| brand | "Armani" |
| categorie | "Pantalon" |
| createdAt | 19 février 2026 |
| createdBy | "user1" |
| imageBase64 | (string base64 JPEG) |
| price | 20 |
| size | "40" |
| title | "Jean regularrr" |

> ⚠️ Les règles Firestore sont actuellement en mode **lecture/écriture publique** (`allow read, write: if true`),
> adapté pour un environnement de développement et de démonstration.

---

## 🛠️ Stack technique

| Technologie       | Version                                 |
|-------------------|-----------------------------------------|
| Flutter           | 3.41.1 (channel stable)                 |
| Dart              | 3.11.0 (language version ≥ 3.3)        |
| firebase_core     | ^2.27.0                                 |
| cloud_firestore   | ^4.15.0                                 |
| google_fonts      | ^6.2.1                                  |
| file_picker       | ^10.3.10                                |
| image             | ^4.8.0                                  |
| TensorFlow.js     | 4.17.0 (CDN, chargé dans `index.html`)  |
| MobileNet (TF.js) | 2.1.0 (CDN, chargé dans `index.html`)   |

---
