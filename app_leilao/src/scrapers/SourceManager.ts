import { SourceDriver } from './SourceInterface';
import { LeilaoImovelSource } from './LeilaoImovelSource';
import { CaixaSource } from './CaixaSource';

export class SourceManager {
  static getDriver(slug: string): SourceDriver {
    switch (slug.toLowerCase()) {
      case 'caixa': return new CaixaSource();
      default: return new LeilaoImovelSource();
    }
  }
}
