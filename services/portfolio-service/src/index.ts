import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { router } from './routes';
import { errorHandler } from './middleware/errorHandler';

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use('/health', (_, res) => res.json({ status: 'ok', service: 'portfolio-service' }));
app.use('/api/v1', router);
app.use(errorHandler);

const PORT = process.env.PORT || 3004;
app.listen(PORT, () => console.log(`portfolio-service running on port ${PORT}`));
export default app;
