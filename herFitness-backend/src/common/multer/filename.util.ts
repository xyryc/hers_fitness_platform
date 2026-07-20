import * as fs from 'fs';
import * as path from 'path';

export const uniqueFilename = (
    req: Express.Request,
    file: Express.Multer.File,
    cb: (error: Error | null, filename: string) => void,
) => {
    try {
        const uploadDir = path.join(process.cwd(), 'public/uploads');

        const originalName = file.originalname;
        const ext = path.extname(originalName);
        const base = path.basename(originalName, ext);

        let index = 0;
        let filename = originalName;

        while (fs.existsSync(path.join(uploadDir, filename))) {
            index++;
            filename = `${base}-${index}${ext}`;
        }

        cb(null, filename);
    } catch (err) {
        cb(err as Error, '');
    }
};
