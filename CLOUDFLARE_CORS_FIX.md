# How to Fix Cloudflare R2 CORS Issues

If images are failing to load in your app (especially when running on Web/Chrome or accessing from different domains), it is likely due to Cross-Origin Resource Sharing (CORS) restrictions on your Cloudflare R2 bucket.

## Steps to Fix

1.  **Log in to Cloudflare Dashboard**.
2.  Navigate to **R2** in the sidebar.
3.  Click on your bucket name (e.g., `college-guide`).
4.  Go to the **Settings** tab.
5.  Scroll down to the **CORS Policy** section.
6.  Click **Add CORS Policy** (or Edit).
7.  Paste the following JSON configuration:

```json
[
  {
    "AllowedOrigins": [
      "http://localhost:3000",
      "http://localhost:*",
      "https://your-production-domain.com",
      "*"
    ],
    "AllowedMethods": [
      "GET",
      "HEAD",
      "PUT",
      "POST",
      "DELETE"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag"
    ],
    "MaxAgeSeconds": 3000
  }
]
```

8.  Click **Save**.

## Why this happens?
When your Flutter app (especially in Chrome/Web mode) tries to fetch an image from `https://pub-xyz.r2.dev`, the browser blocks the request if the server (R2) doesn't explicitly allow requests from your app's origin (`http://localhost`).

Setting `AllowedOrigins` to `*` allows any domain to access the resources, which is generally fine for public profile pictures and course content. For stricter security, replace `*` with your specific production domains.
