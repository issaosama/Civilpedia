class Draft {
  constructor() {
    this.data = null;
    this.fileName = '';
  }

  load(jsonString, fileName) {
    const parsed = JSON.parse(jsonString);
    if (!parsed || typeof parsed !== 'object') {
      throw new Error('JSON must be an object');
    }
    this.data = parsed;
    this.fileName = fileName || 'untitled.draft.json';
    return true;
  }

  isValid() {
    return this.data !== null;
  }

  getTopLevelKeys() {
    return this.data ? Object.keys(this.data) : [];
  }

  getField(path) {
    if (!this.data) return undefined;
    const parts = path.split('.');
    let current = this.data;
    for (const part of parts) {
      if (current === null || current === undefined || typeof current !== 'object') {
        return undefined;
      }
      if (Array.isArray(current)) {
        const idx = parseInt(part, 10);
        if (isNaN(idx) || idx < 0 || idx >= current.length) return undefined;
        current = current[idx];
      } else {
        if (!(part in current)) return undefined;
        current = current[part];
      }
    }
    return current;
  }

  setField(path, value) {
    if (!this.data) return false;
    const parts = path.split('.');
    let current = this.data;
    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i];
      if (Array.isArray(current)) {
        const idx = parseInt(part, 10);
        if (isNaN(idx) || idx < 0 || idx >= current.length) return false;
        current = current[idx];
      } else {
        if (!(part in current) || current[part] === null || typeof current[part] !== 'object') {
          current[part] = {};
        }
        current = current[part];
      }
    }
    const lastPart = parts[parts.length - 1];
    if (Array.isArray(current)) {
      const idx = parseInt(lastPart, 10);
      if (isNaN(idx) || idx < 0 || idx >= current.length) return false;
      current[idx] = value;
    } else {
      current[lastPart] = value;
    }
    return true;
  }

  toJSON() {
    return this.data ? JSON.parse(JSON.stringify(this.data)) : null;
  }

  serialize(pretty = true) {
    return pretty ? JSON.stringify(this.data, null, 2) : JSON.stringify(this.data);
  }
}
