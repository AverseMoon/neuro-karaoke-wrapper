import { Site } from "./main";

/**
 * Application configuration
 */
export default {
  // Discord Rich Presence
  // Replace with your Discord Application ID from https://discord.com/developers/applications
  discordClientId: '1464192200849100862',

  // Window settings
  window: {
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    backgroundColor: '#1a1a1a'
  },

  // URLs
  url: {
    neuro: 'https://neurokaraoke.com/',
    evil: 'https://evilkaraoke.com/',
    smocus: 'https://twinskaraoke.com/',
    test: process.env.TEST_SITE_LINK ?? 'https://neurokaraoke.com/', // i asked soul about this and he requested i dont put the actual test site here so people dont do bug reports on it
  },
  
  allowedHosts: new Set([
    'www.neurokaraoke.com', 'neurokaraoke.com',
    'www.evilkaraoke.com', 'evilkaraoke.com',
    'www.twinskaraoke.com', 'twinskaraoke.com',
    'eu.twinskaraoke.com',
    'cn.neurokaraoke.com',
    'discord.com', 'www.discord.com',
    ...(process.env.TEST_SITE_LINK ? [new URL(process.env.TEST_SITE_LINK).hostname] : [])
  ]),

  // App metadata
  app: {
    id: 'com.neurokaraoke.app',
    name: 'Neuro Karaoke',
    partition: 'persist:neurokaraoke',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36'
  },
} satisfies {
  discordClientId: string,
  window: {
    width: number,
    height: number,
    minWidth: number,
    minHeight: number,
    backgroundColor: string,
  },
  url: Record<Site, string>,
  allowedHosts: Set<string>,
  app: {
    id: string,
    name: string,
    partition: string,
    userAgent: string,
  },
};
