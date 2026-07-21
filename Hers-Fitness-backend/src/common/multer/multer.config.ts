import { memoryStorage } from 'multer';
import { imageFileFilter } from './file-filter.util';

export const multerConfig = {
    storage: memoryStorage(),

    fileFilter: imageFileFilter,

    limits: {
        fileSize: 50 * 1024 * 1024  // 50MB limit
    }
};
