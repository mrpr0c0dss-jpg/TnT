const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('node:crypto');

const R2_BUCKET = process.env.R2_BUCKET_NAME || 'tnt';
const R2_PUBLIC_URL = (process.env.R2_PUBLIC_URL || 'https://pub-19f99fefef0f4b8b991275070c52a390.r2.dev').replace(/\/+$/, '');
const R2_ENDPOINT = process.env.R2_ENDPOINT || 'https://e04704a407c828d0c0d43d4ddd303c89.r2.cloudflarestorage.com';

const s3Client = new S3Client({
  region: 'auto',
  endpoint: R2_ENDPOINT,
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '9725be9cda28c629f7e383f259d29403',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || 'ccf2a42578a6eaddcdc222ac35ab3a5ddc31b67649593c476a06fba90d132a33',
  },
});

/**
 * Upload a binary Buffer to Cloudflare R2 bucket and return the public URL
 */
async function uploadToR2({ buffer, filename = 'image.png', contentType = 'image/png' }) {
  const cleanExt = (filename.match(/\.[a-zA-Z0-9]+$/) || ['.png'])[0].toLowerCase();
  const safeBase = filename.replace(/\.[a-zA-Z0-9]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 20) || 'upload';
  const objectKey = `${safeBase}_${Date.now()}_${crypto.randomUUID().slice(0, 8)}${cleanExt}`;

  const command = new PutObjectCommand({
    Bucket: R2_BUCKET,
    Key: objectKey,
    Body: buffer,
    ContentType: contentType,
  });

  await s3Client.send(command);

  const publicUrl = `${R2_PUBLIC_URL}/${objectKey}`;
  return {
    url: publicUrl,
    key: objectKey,
    bucket: R2_BUCKET,
    sizeBytes: buffer.length,
    contentType,
  };
}

module.exports = {
  s3Client,
  uploadToR2,
  R2_BUCKET,
  R2_PUBLIC_URL,
};
