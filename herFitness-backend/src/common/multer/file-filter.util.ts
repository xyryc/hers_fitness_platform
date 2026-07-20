export const imageFileFilter = (
    req: Express.Request,
    file: Express.Multer.File,
    cb: (error: Error | null, acceptFile: boolean) => void,
) => {
    try {
        if (!file.mimetype.startsWith('image/')) {
            return cb(
                new Error('Only image files are allowed'),
                false,
            );
        }

        cb(null, true);
    } catch (err) {
        cb(err as Error, false);
    }
};
