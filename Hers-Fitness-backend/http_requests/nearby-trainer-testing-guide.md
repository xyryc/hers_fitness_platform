# Nearby Trainer Postman Guide

## Files
- Postman collection: `http_requests/nearby-trainer.postman_collection.json`

Import `http_requests/nearby-trainer.postman_collection.json` into Postman.

## Base Setup
- `base_url` = `http://localhost:5001`
- Use the Docker PostGIS database on port `5433` in `.env`
- Start the API with `pnpm start:dev`

## Tokens You Need
- `trainer_token`: access token from a trainer login
- `member_token`: access token from a member login
- `trainer_id`: the trainer user id for the profile endpoint

## Recommended Test Order
1. Login as trainer and save the returned access token as `trainer_token`
2. Create at least one trainer class using `POST /api/trainer/classes`
3. Set trainer base location
4. Update trainer live location
5. Set trainer online status to `true`
6. Login as member and save the returned access token as `member_token`
7. Set member current location
8. Call nearby trainers
9. Call search trainers
10. Call single trainer profile using that trainer's id

## Endpoint List

### 1. Set Trainer Base Location
- Method: `POST`
- URL: `{{base_url}}/api/location/trainer/base`
- Auth: `Bearer {{trainer_token}}`
- Body:

```json
{
  "lat": 23.8103,
  "lng": 90.4125
}
```

### 2. Update Trainer Live Location
- Method: `PUT`
- URL: `{{base_url}}/api/location/trainer/live`
- Auth: `Bearer {{trainer_token}}`
- Body:

```json
{
  "lat": 23.8115,
  "lng": 90.4138
}
```

### 3. Clear Trainer Live Location
- Method: `DELETE`
- URL: `{{base_url}}/api/location/trainer/live`
- Auth: `Bearer {{trainer_token}}`

This clears live coordinates and sets `isOnline` to `false`.

### 4. Update Trainer Online Status
- Method: `PUT`
- URL: `{{base_url}}/api/location/trainer/status`
- Auth: `Bearer {{trainer_token}}`
- Body:

```json
{
  "isOnline": true
}
```

### 5. Set Member Current Location
- Method: `POST`
- URL: `{{base_url}}/api/location/member`
- Auth: `Bearer {{member_token}}`
- Body:

```json
{
  "lat": 23.8098,
  "lng": 90.4102
}
```

### 6. Get Nearby Trainers
- Method: `GET`
- URL: `{{base_url}}/api/trainers/nearby?lat=23.8098&lng=90.4102&radius_km=10`
- Auth: `Bearer {{member_token}}`

Expected behavior:
- if trainer `isOnline = true` and live location exists, distance is based on live location
- otherwise distance is based on base location
- response includes:
  - `distanceMeters`
  - `locationLabel`

Possible `locationLabel` values:
- `Active Now`
- `Based Nearby`

### 7. Search Trainers
- Method: `GET`
- URL:

```text
{{base_url}}/api/trainers/search?specialty=Yoga&price_min=10&price_max=100&name=Sara
```

- Auth: `Bearer {{member_token}}`

All query params are optional:
- `specialty`
- `price_min`
- `price_max`
- `name`

### 8. Get Trainer Profile
- Method: `GET`
- URL:

```text
{{base_url}}/api/trainers/{{trainer_id}}?lat=23.8098&lng=90.4102
```

- Auth: `Bearer {{member_token}}`

If `lat` and `lng` are passed, the response includes `distanceMeters`.

## Useful Notes
- Discovery endpoints are member-only in the current implementation.
- Trainer discovery returns useful results only for active approved trainers.
- The trainer should have at least one active class if you want `startingPrice` or `activeClasses` to be meaningful.
- Base location is the fallback location when the trainer is offline.

## Quick Troubleshooting
- `401 Unauthorized`: token missing, expired, or wrong role
- `404 Trainer not found`: wrong `trainer_id` or trainer is not available in the expected state
- empty nearby results: trainer may be too far away, offline without base location, or missing class/profile data
- PostGIS errors: make sure you are still pointing to the Docker DB on port `5433`
