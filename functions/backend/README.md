# Backend Cloud Functions

## Quiz Challenges

Firestore collection: `quiz_challenges`

Required fields per document:
- `categoryId`
- `score`
- `createdByUid`
- `createdAt`
- `expiresAt` (optional TTL timestamp)

### Public challenge endpoint

`GET /challenge/{challengeId}`

Response payload:
```
{
  "challengeId": "...",
  "categoryName": "...",
  "score": 12
}
```

The endpoint intentionally excludes user PII (no `createdByUid`).

### Sample Firestore rules

```
match /quiz_challenges/{challengeId} {
  allow read: if true;
  allow write: if false;
}
```

## Deploy

From the repo root:

```
cd functions/backend
npm install
npm run build
firebase deploy --only functions:backend
```

To deploy Firestore rules alongside functions:

```
firebase deploy --only functions:backend,firestore:rules
```
