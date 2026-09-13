import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { basename, extname } from 'node:path';
import { randomUUID } from 'node:crypto';
import { Readable } from 'node:stream';
import { R2Provider } from './storage/r2.provider';

export enum UploadKind {
  IMAGES = 'images',
  VIDEOS = 'videos',
}

export interface UploadedFileData {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

export interface UploadResult {
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  url: string;
}

export interface StoredFile {
  stream: Readable;
  mimeType: string;
  size: number;
  contentRange?: string;
}

const IMAGE_TYPES: Readonly<Record<string, string>> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

const VIDEO_TYPES: Readonly<Record<string, string>> = {
  'video/mp4': '.mp4',
  'video/webm': '.webm',
  'video/quicktime': '.mov',
};

const MIME_BY_EXTENSION: Readonly<Record<string, string>> = {
  ...Object.fromEntries(
    Object.entries(IMAGE_TYPES).map(([mimeType, extension]) => [
      extension,
      mimeType,
    ]),
  ),
  ...Object.fromEntries(
    Object.entries(VIDEO_TYPES).map(([mimeType, extension]) => [
      extension,
      mimeType,
    ]),
  ),
};

@Injectable()
export class UploadsService {
  constructor(private readonly r2: R2Provider) {}

  saveImage(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.IMAGES, IMAGE_TYPES, 10 * 1024 * 1024);
  }

  saveVideo(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.VIDEOS, VIDEO_TYPES, 100 * 1024 * 1024);
  }

  async open(
    kind: UploadKind,
    filename: string,
    rangeHeader?: string,
  ): Promise<StoredFile> {
    const safeFilename = basename(filename);
    if (safeFilename !== filename) {
      throw new BadRequestException('Invalid filename');
    }

    const key = `${kind}/${safeFilename}`;

    try {
      const object = await this.r2.head(key);
      const fileSize = object.ContentLength;
      if (fileSize === undefined) throw new NotFoundException('File not found');

      const range = this.parseRange(rangeHeader, fileSize);
      const downloaded = await this.r2.download(
        key,
        range ? `bytes=${range.start}-${range.end}` : undefined,
      );
      if (!downloaded.Body) throw new NotFoundException('File not found');

      return {
        stream: downloaded.Body as Readable,
        mimeType:
          object.ContentType ??
          MIME_BY_EXTENSION[extname(safeFilename).toLowerCase()] ??
          'application/octet-stream',
        size: range ? range.end - range.start + 1 : fileSize,
        contentRange: range
          ? `bytes ${range.start}-${range.end}/${fileSize}`
          : undefined,
      };
    } catch (error: unknown) {
      const r2Error = error as { name?: string; Code?: string };
      if (
        r2Error.name === 'NoSuchKey' ||
        r2Error.name === 'NotFound' ||
        r2Error.Code === 'NoSuchKey'
      ) {
        throw new NotFoundException('File not found');
      }
      throw error;
    }
  }

  private parseRange(
    rangeHeader: string | undefined,
    fileSize: number,
  ): { start: number; end: number } | undefined {
    if (!rangeHeader) return undefined;

    const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader.trim());
    if (!match || (!match[1] && !match[2]) || fileSize === 0) {
      this.throwInvalidRange(fileSize);
    }

    const startText = match[1];
    const endText = match[2];
    let start: number;
    let end: number;

    if (!startText) {
      const suffixLength = Number(endText);
      if (!Number.isSafeInteger(suffixLength) || suffixLength <= 0) {
        this.throwInvalidRange(fileSize);
      }
      start = Math.max(fileSize - suffixLength, 0);
      end = fileSize - 1;
    } else {
      start = Number(startText);
      end = endText ? Number(endText) : fileSize - 1;
    }

    if (
      !Number.isSafeInteger(start) ||
      !Number.isSafeInteger(end) ||
      start < 0 ||
      start >= fileSize ||
      end < start
    ) {
      this.throwInvalidRange(fileSize);
    }

    return { start, end: Math.min(end, fileSize - 1) };
  }

  private throwInvalidRange(fileSize: number): never {
    throw new HttpException(
      {
        statusCode: HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE,
        message: 'Requested range not satisfiable',
        contentRange: `bytes */${fileSize}`,
      },
      HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE,
    );
  }

  private async save(
    file: UploadedFileData | undefined,
    kind: UploadKind,
    allowedTypes: Readonly<Record<string, string>>,
    maxSize: number,
  ): Promise<UploadResult> {
    if (!file) throw new BadRequestException('File is required');

    const extension = allowedTypes[file.mimetype];
    if (!extension) {
      throw new BadRequestException(
        `Unsupported file type: ${file.mimetype || 'unknown'}`,
      );
    }
    if (file.size > maxSize) {
      throw new BadRequestException(
        `File size must not exceed ${maxSize / 1024 / 1024} MB`,
      );
    }

    const filename = `${randomUUID()}${extension}`;
    await this.r2.upload(`${kind}/${filename}`, file.buffer, file.mimetype);

    return {
      filename,
      originalName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
      url: `/uploads/${kind}/${filename}`,
    };
  }
}
