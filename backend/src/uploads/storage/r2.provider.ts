import {
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class R2Provider {
  private readonly client: S3Client;

  constructor(private readonly config: ConfigService) {
    this.client = new S3Client({
      region: 'auto',
      endpoint: `https://${this.config.getOrThrow<string>('r2.accountId')}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: this.config.getOrThrow<string>('r2.accessKeyId'),
        secretAccessKey: this.config.getOrThrow<string>('r2.secretAccessKey'),
      },
    });
  }

  async upload(key: string, body: Buffer, contentType: string) {
    const command = new PutObjectCommand({
      Bucket: this.config.getOrThrow<string>('r2.bucketName'),
      Key: key,
      Body: body,
      ContentType: contentType,
    });

    return this.client.send(command);
  }

  head(key: string) {
    return this.client.send(
      new HeadObjectCommand({
        Bucket: this.config.getOrThrow<string>('r2.bucketName'),
        Key: key,
      }),
    );
  }

  download(key: string, range?: string) {
    return this.client.send(
      new GetObjectCommand({
        Bucket: this.config.getOrThrow<string>('r2.bucketName'),
        Key: key,
        Range: range,
      }),
    );
  }
}
