# 🧪 Quick Testing Guide - Authentication System

## Prerequisites

- Django backend running on `http://127.0.0.1:8000`
- Flutter app ready to run

## Test Scenarios

### ✅ Scenario 1: New User Registration

1. **Launch Flutter App**

   ```bash
   cd frontend
   flutter run
   ```

2. **You should see**: LoginScreen (since no token is stored)

3. **Tap "Create an account"** → Navigates to RegisterScreen

4. **Fill the form**:

   - Username: `testuser123`
   - Email: `test@example.com`
   - First Name: `John` (optional)
   - Last Name: `Doe` (optional)
   - Password: `SecurePass123`
   - Confirm Password: `SecurePass123`

5. **Tap "Create Account"**

6. **Expected Result**:
   - ✅ Loading indicator appears
   - ✅ Request sent to backend
   - ✅ Token saved securely
   - ✅ Navigation back to LoginScreen
   - ✅ User can now login

### ✅ Scenario 2: User Login

1. **On LoginScreen**, enter:

   - Username: `testuser123`
   - Password: `SecurePass123`

2. **Tap "Sign In"**

3. **Expected Result**:
   - ✅ Loading indicator appears
   - ✅ Token retrieved and saved
   - ✅ Navigate to MainScreen
   - ✅ See Posts and Analytics tabs
   - ✅ Logout button in AppBar

### ✅ Scenario 3: API Calls with Token

1. **On MainScreen**, navigate to different tabs:

   - **Posts Tab**: API calls include `Authorization: Token <token>`
   - **Analytics Tab**: All analytics endpoints include token

2. **Check Network Logs** (optional):

   ```bash
   # In backend terminal, you'll see:
   # "GET /api/posts/ HTTP/1.1" 200
   # "GET /api/posts/stats/ HTTP/1.1" 200
   ```

3. **Expected Result**:
   - ✅ All API calls succeed
   - ✅ Data loads normally
   - ✅ No authentication errors

### ✅ Scenario 4: Token Persistence

1. **Close the Flutter app completely**

2. **Reopen the app**

3. **Expected Result**:
   - ✅ App checks for stored token
   - ✅ Token found
   - ✅ Auto-navigate to MainScreen (skip login)
   - ✅ User still authenticated

### ✅ Scenario 5: Logout

1. **On MainScreen**, tap the **Logout button** (top-right)

2. **Expected Result**:
   - ✅ Token deleted from storage
   - ✅ Auth state updated
   - ✅ Navigate to LoginScreen
   - ✅ Cannot access MainScreen anymore

### ✅ Scenario 6: Invalid Login

1. **On LoginScreen**, enter:

   - Username: `wronguser`
   - Password: `wrongpass`

2. **Tap "Sign In"**

3. **Expected Result**:
   - ✅ Loading indicator appears
   - ✅ Error response from backend
   - ✅ Red error snackbar appears
   - ✅ Message: "Invalid credentials"
   - ✅ Stay on LoginScreen

### ✅ Scenario 7: Form Validation

**LoginScreen**:

1. Try submitting with empty fields → ❌ "Please enter username"
2. Enter only username → ❌ "Please enter password"

**RegisterScreen**:

1. Username < 3 chars → ❌ "Username must be at least 3 characters"
2. Invalid email → ❌ "Please enter a valid email"
3. Password < 8 chars → ❌ "Password must be at least 8 characters"
4. Passwords don't match → ❌ "Passwords do not match"

---

## 🔍 Backend Verification

### Check User in Database

```bash
cd backend
source venv/bin/activate
python manage.py shell
```

```python
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

# List all users
users = User.objects.all()
for user in users:
    print(f"{user.id}: {user.username} - {user.email}")

# Check tokens
tokens = Token.objects.all()
for token in tokens:
    print(f"User: {token.user.username} → Token: {token.key}")
```

### Test API Endpoints Manually

```bash
# Register
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "curltester",
    "email": "curl@example.com",
    "password": "CurlPass123",
    "password2": "CurlPass123"
  }'

# Login
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "curltester",
    "password": "CurlPass123"
  }'

# Profile (replace TOKEN with actual token)
curl -X GET http://127.0.0.1:8000/api/auth/profile/ \
  -H "Authorization: Token TOKEN"

# Logout (replace TOKEN)
curl -X POST http://127.0.0.1:8000/api/auth/logout/ \
  -H "Authorization: Token TOKEN"
```

---

## 🐛 Troubleshooting

### Issue: "Connection refused"

**Solution**: Make sure Django server is running

```bash
cd backend
source venv/bin/activate
python manage.py runserver
```

### Issue: "Invalid token" / 401 Unauthorized

**Solution**: Token might be expired or deleted

- Try logging out and logging back in
- Check token exists in database

### Issue: Flutter app shows blank screen

**Solution**: Check console for errors

```bash
# In terminal running Flutter
flutter logs
```

### Issue: Registration fails with "duplicate key"

**Solution**: Username or email already exists

- Use a different username
- Check existing users in Django admin

### Issue: Token not persisting across restarts

**Solution**: Check flutter_secure_storage is installed

```bash
cd frontend
flutter pub get
```

---

## 📊 Expected Test Results Summary

| Test                            | Expected Outcome                        | Status |
| ------------------------------- | --------------------------------------- | ------ |
| Register new user               | User created, token saved               | ✅     |
| Login with correct credentials  | Token retrieved, navigate to MainScreen | ✅     |
| Login with wrong credentials    | Error message, stay on LoginScreen      | ✅     |
| API calls while authenticated   | All succeed with token                  | ✅     |
| App restart while authenticated | Auto-login, skip LoginScreen            | ✅     |
| Logout                          | Token deleted, back to LoginScreen      | ✅     |
| Access app without token        | Show LoginScreen                        | ✅     |
| Form validation                 | Errors for invalid input                | ✅     |

---

## 🎯 Next Steps After Testing

1. **If all tests pass**: Authentication is fully functional! ✅
2. **If issues found**: Check troubleshooting section above
3. **Optional enhancements**:
   - Add profile edit screen
   - Add password change UI
   - Add email verification
   - Add "Remember Me" option
   - Add social authentication

---

## 📝 Test Checklist

Copy this checklist and mark items as you test:

```
Backend Tests:
[ ] Can register via curl
[ ] Can login via curl
[ ] Can access profile with token
[ ] Cannot access profile without token
[ ] Can logout (token deleted)

Frontend Tests:
[ ] App shows LoginScreen on first launch
[ ] Can navigate to RegisterScreen
[ ] Registration form validates input
[ ] Registration creates account
[ ] Login form validates input
[ ] Login succeeds with correct credentials
[ ] Login fails with wrong credentials
[ ] MainScreen shows after login
[ ] Logout button works
[ ] Token persists across app restarts
[ ] API calls include auth token

Integration Tests:
[ ] Complete flow: Register → Login → Use App → Logout
[ ] Token auto-loads on app restart
[ ] No errors in console logs
```

---

**Happy Testing! 🚀**

If you encounter any issues, refer to the troubleshooting section or check the detailed documentation in `MILESTONE_4_AUTH_COMPLETE.md`.
